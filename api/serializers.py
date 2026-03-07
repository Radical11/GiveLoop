from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.utils import timezone
from .models import Charity, NeedRequest, Donation, ImpactUpdate, Team, Badge, UserBadge

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'role', 'give_coins', 'streak_days', 'location', 'last_donation_date']
        read_only_fields = ['give_coins', 'streak_days', 'last_donation_date']

class CharitySerializer(serializers.ModelSerializer):
    admin = UserSerializer(read_only=True)
    
    class Meta:
        model = Charity
        fields = ['id', 'admin', 'name', 'verified', 'description', 'contact', 'location']

class NeedRequestSerializer(serializers.ModelSerializer):
    charity = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = NeedRequest
        fields = ['id', 'charity', 'category', 'title', 'qty_needed', 'qty_pledged', 'urgency', 'deadline', 'status']
        read_only_fields = ['qty_pledged', 'status']

    def validate_deadline(self, value):
        # Allow a small grace period (2 mins) to avoid 400s during tests/network lag
        if value < timezone.now() - timezone.timedelta(minutes=2):
            raise serializers.ValidationError("Deadline cannot be in the past.")
        return value

    def validate(self, data):
        if self.instance and 'qty_needed' in data:
            if data['qty_needed'] < self.instance.qty_pledged:
                raise serializers.ValidationError({
                    "qty_needed": f"Cannot lower needed quantity below current pledges ({self.instance.qty_pledged})."
                })
        return data

class DonationSerializer(serializers.ModelSerializer):
    donor = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = Donation
        fields = ['id', 'donor', 'need_request', 'qty', 'status', 'created_at']
        read_only_fields = ['status']

    def validate(self, data):
        # Validate that donor is actually a donor
        user = self.context['request'].user
        if getattr(user, 'role', None) != 'donor':
            raise serializers.ValidationError({"donor": "Only users with the donor role can make pledges."})

        # Validate that qty doesn't exceed qty_needed
        need_request = data['need_request']
        if (data['qty'] + need_request.qty_pledged) > need_request.qty_needed:
            raise serializers.ValidationError(
                {"qty": f"Cannot pledge {data['qty']} items. Only {need_request.qty_needed - need_request.qty_pledged} needed."}
            )
        
        return data

class ImpactUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ImpactUpdate
        fields = ['id', 'charity', 'donation', 'photo', 'caption', 'created_at']

class TeamSerializer(serializers.ModelSerializer):
    creator = serializers.PrimaryKeyRelatedField(read_only=True)
    members = serializers.PrimaryKeyRelatedField(many=True, read_only=True)

    class Meta:
        model = Team
        fields = ['id', 'name', 'creator', 'members', 'challenge_goal', 'challenge_deadline']

class BadgeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Badge
        fields = ['id', 'name', 'description', 'icon', 'criteria_type', 'criteria_value']

class UserBadgeSerializer(serializers.ModelSerializer):
    badge = BadgeSerializer(read_only=True)
    class Meta:
        model = UserBadge
        fields = ['id', 'user', 'badge', 'earned_at']


class DonationStatusSerializer(serializers.Serializer):
    """Used for PATCH /api/donations/<id>/status/ — charity admin updates donation status."""
    STATUS_CHOICES = ['confirmed', 'received']
    status = serializers.ChoiceField(choices=STATUS_CHOICES)
