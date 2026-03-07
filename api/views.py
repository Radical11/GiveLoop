from rest_framework import generics, status, viewsets, serializers as drf_serializers
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404

from .models import Charity, NeedRequest, Donation, ImpactUpdate, Team, Badge, UserBadge
from .serializers import (
    UserSerializer, CharitySerializer, NeedRequestSerializer,
    DonationSerializer, ImpactUpdateSerializer,
    TeamSerializer, BadgeSerializer, UserBadgeSerializer,
    DonationStatusSerializer,
)
from rest_framework.exceptions import PermissionDenied
from .permissions import IsCharityAdmin, IsDonor, IsObjectOwner

User = get_user_model()


# ---------------------------------------------------------------------------
# Auth Endpoints
# ---------------------------------------------------------------------------
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView


class RegisterSerializer(UserSerializer):
    """Extends UserSerializer to accept password on creation."""
    password = drf_serializers.CharField(write_only=True)

    class Meta(UserSerializer.Meta):
        fields = UserSerializer.Meta.fields + ['password']

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


@api_view(['POST'])
@permission_classes([AllowAny])
def register_view(request):
    """POST /api/auth/register/ — Create a new Donor or Charity Admin."""
    serializer = RegisterSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    user = serializer.save()
    return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    """POST /api/auth/logout/ — Acknowledge logout (token deletion is client-side with JWT)."""
    return Response({'detail': 'Successfully logged out.'}, status=status.HTTP_200_OK)


# ---------------------------------------------------------------------------
# User Endpoints
# ---------------------------------------------------------------------------
@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def profile_view(request):
    """GET/PATCH /api/users/profile/ — View or edit own profile."""
    if request.method == 'GET':
        return Response(UserSerializer(request.user).data)
    serializer = UserSerializer(request.user, data=request.data, partial=True)
    serializer.is_valid(raise_exception=True)
    serializer.save()
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([AllowAny])
def leaderboard_view(request):
    """GET /api/users/leaderboard/ — Top donors ordered by give_coins."""
    top = User.objects.filter(role='donor').order_by('-give_coins')[:20]
    return Response(UserSerializer(top, many=True).data)


# ---------------------------------------------------------------------------
# Charity Endpoints
# ---------------------------------------------------------------------------
class CharityViewSet(viewsets.ModelViewSet):
    queryset = Charity.objects.all().order_by('id')
    serializer_class = CharitySerializer

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [IsAuthenticated(), IsCharityAdmin(), IsObjectOwner()]
        return [AllowAny()]

    def perform_create(self, serializer):
        serializer.save(admin=self.request.user)


# ---------------------------------------------------------------------------
# NeedRequest Endpoints
# ---------------------------------------------------------------------------
class NeedRequestViewSet(viewsets.ModelViewSet):
    serializer_class = NeedRequestSerializer
    filterset_fields = ['category', 'status', 'urgency', 'charity__location']

    def get_queryset(self):
        queryset = NeedRequest.objects.all()
        # Filter by charity if nested
        charity_id = self.kwargs.get('charity_pk')
        if charity_id:
            queryset = queryset.filter(charity_id=charity_id)
        
        # Filter by charity location if provided in query param
        location = self.request.query_params.get('location')
        if location:
            queryset = queryset.filter(charity__location__icontains=location)
            
        return queryset.order_by('-urgency', 'deadline')

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [IsAuthenticated(), IsCharityAdmin(), IsObjectOwner()]
        return [AllowAny()]

    def perform_create(self, serializer):
        charity_id = self.kwargs.get('charity_pk')
        try:
            charity = Charity.objects.get(pk=charity_id, admin=self.request.user)
            serializer.save(charity=charity)
        except Charity.DoesNotExist:
            raise PermissionDenied("You can only create needs for your own charity.")


# ---------------------------------------------------------------------------
# Donation (Pledge) Endpoints
# ---------------------------------------------------------------------------
@api_view(['POST'])
@permission_classes([IsAuthenticated, IsDonor])
def pledge_view(request):
    """POST /api/donations/pledge/ — Create a donation pledge atomically."""
    serializer = DonationSerializer(data=request.data, context={'request': request})
    serializer.is_valid(raise_exception=True)
    serializer.save(donor=request.user)
    return Response(serializer.data, status=status.HTTP_201_CREATED)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def donation_history_view(request):
    """GET /api/donations/history/ — Current user's donation history."""
    donations = Donation.objects.filter(donor=request.user).order_by('-created_at')
    return Response(DonationSerializer(donations, many=True).data)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated, IsCharityAdmin])
def donation_status_view(request, pk):
    """
    PATCH /api/donations/<id>/status/ — Charity admin updates donation status.
    Allowed transitions: pledged → confirmed → received.
    Only the charity admin who owns the related NeedRequest's charity can do this.
    """
    donation = get_object_or_404(Donation, pk=pk)
    if donation.need_request.charity.admin != request.user:
        return Response(
            {'detail': 'You are not the admin of the charity for this donation.'},
            status=status.HTTP_403_FORBIDDEN,
        )
    serializer = DonationStatusSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    new_status = serializer.validated_data['status']
    valid_transitions = {
        'pledged': ['confirmed'],
        'confirmed': ['received'],
    }
    if new_status not in valid_transitions.get(donation.status, []):
        return Response(
            {'detail': f"Invalid transition: '{donation.status}' → '{new_status}'."},
            status=status.HTTP_400_BAD_REQUEST,
        )
    donation.status = new_status
    donation.save()
    return Response(DonationSerializer(donation).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated, IsCharityAdmin])
def charity_pledges_view(request):
    """
    GET /api/charities/pledges/ — Charity admin views all incoming donation pledges
    for their charity's need requests, ordered newest first.
    """
    charity = get_object_or_404(Charity, admin=request.user)
    donations = (
        Donation.objects
        .filter(need_request__charity=charity)
        .order_by('-created_at')
        .select_related('donor', 'need_request')
    )
    return Response(DonationSerializer(donations, many=True).data)


# ---------------------------------------------------------------------------
# Impact Update Endpoints
# ---------------------------------------------------------------------------
class ImpactUpdateViewSet(viewsets.ModelViewSet):
    queryset = ImpactUpdate.objects.all().order_by('-created_at')
    serializer_class = ImpactUpdateSerializer

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [IsAuthenticated(), IsCharityAdmin(), IsObjectOwner()]
        return [AllowAny()]

    def perform_create(self, serializer):
        donation = serializer.validated_data['donation']
        # Double check that the donation belongs to the admin's charity
        if donation.need_request.charity.admin != self.request.user:
            raise PermissionDenied("You can only provide updates for donations to your charity.")
        serializer.save(charity=donation.need_request.charity)


# ---------------------------------------------------------------------------
# Team Endpoints
# ---------------------------------------------------------------------------
class TeamViewSet(viewsets.ModelViewSet):
    queryset = Team.objects.all().order_by('id')
    serializer_class = TeamSerializer

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [IsAuthenticated(), IsObjectOwner()]
        return [AllowAny()]

    def perform_create(self, serializer):
        team = serializer.save(creator=self.request.user)
        team.members.add(self.request.user)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def join(self, request, pk=None):
        """POST /api/teams/<id>/join/ — Join an existing team."""
        team = self.get_object()
        team.members.add(request.user)
        return Response({'status': f'Joined team {team.name}'})

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def leave(self, request, pk=None):
        """POST /api/teams/<id>/leave/ — Leave a team."""
        team = self.get_object()
        if team.creator == request.user:
            return Response({'error': 'Creators cannot leave their own team. Delete it instead.'}, status=status.HTTP_400_BAD_REQUEST)
        team.members.remove(request.user)
        return Response({'status': f'Left team {team.name}'})

    @action(detail=True, methods=['get'], permission_classes=[AllowAny])
    def leaderboard(self, request, pk=None):
        """GET /api/teams/<id>/leaderboard/ — Team members ranked by GiveCoins."""
        team = self.get_object()
        members = team.members.all().order_by('-give_coins')
        return Response(UserSerializer(members, many=True).data)


# ---------------------------------------------------------------------------
# Gamification Endpoints
# ---------------------------------------------------------------------------
class BadgeViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Badge.objects.all().order_by('criteria_value')
    serializer_class = BadgeSerializer
    permission_classes = [AllowAny]


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_badges_view(request):
    """GET /api/badges/mine/ — Current user's earned badges."""
    user_badges = UserBadge.objects.filter(user=request.user).select_related('badge')
    return Response(UserBadgeSerializer(user_badges, many=True).data)
