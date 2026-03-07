from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from . import views

router = DefaultRouter()
router.register(r'charities', views.CharityViewSet, basename='charity')
router.register(r'impact-updates', views.ImpactUpdateViewSet, basename='impact-update')
router.register(r'teams', views.TeamViewSet, basename='team')
router.register(r'badges', views.BadgeViewSet, basename='badge')

urlpatterns = [
    # Auth
    path('auth/register/', views.register_view, name='register'),
    path('auth/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/logout/', views.logout_view, name='logout'),

    # User
    path('users/profile/', views.profile_view, name='profile'),
    path('users/leaderboard/', views.leaderboard_view, name='leaderboard'),

    # Nested NeedRequests under Charities
    path('charities/<int:charity_pk>/needs/',
         views.NeedRequestViewSet.as_view({'get': 'list', 'post': 'create'}),
         name='charity-needs-list'),
    path('charities/<int:charity_pk>/needs/<int:pk>/',
         views.NeedRequestViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}),
         name='charity-needs-detail'),

    # Also allow flat listing of all needs
    path('needs/',
         views.NeedRequestViewSet.as_view({'get': 'list'}),
         name='needs-list'),

    # Donations
    path('donations/pledge/', views.pledge_view, name='pledge'),
    path('donations/history/', views.donation_history_view, name='donation-history'),
    path('donations/<int:pk>/status/', views.donation_status_view, name='donation-status'),

    # Charity incoming pledges
    path('charities/pledges/', views.charity_pledges_view, name='charity-pledges'),

    # Badges
    path('badges/mine/', views.my_badges_view, name='my-badges'),

    # Router URLs (charities, impact-updates, teams, badges)
    # Note: router includes /teams/<id>/leaderboard/ and /teams/<id>/join/ and /teams/<id>/leave/
    path('', include(router.urls)),
]
