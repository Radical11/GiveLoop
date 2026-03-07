"""
Comprehensive test suite for the GiveLoop API.

Covers:
  - User registration & authentication (JWT)
  - Profile read/update
  - Leaderboard
  - Charity CRUD
  - NeedRequest CRUD & filtering
  - Donation pledging (validation + atomic qty_pledged updates)
  - Gamification (GiveCoin awards on status transition)
  - Badge unlock logic
  - Team create / join / leave
  - ImpactUpdate CRUD
  - Permission checks (role enforcement)
"""
from django.test import TestCase, override_settings
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from django.utils import timezone
from datetime import timedelta

from api.models import (
    Charity, NeedRequest, Donation, ImpactUpdate,
    Team, Badge, UserBadge,
)

User = get_user_model()


# Disable channel layer during tests to avoid broadcast errors
@override_settings(CHANNEL_LAYERS={"default": {"BACKEND": "channels.layers.InMemoryChannelLayer"}})
class BaseTestCase(TestCase):
    """Shared setup for all test classes."""

    def setUp(self):
        self.client = APIClient()

        # Create a donor
        self.donor = User.objects.create_user(
            username='test_donor', password='testpass123',
            email='donor@test.com', role='donor'
        )
        # Create a charity admin
        self.charity_admin = User.objects.create_user(
            username='test_charity_admin', password='testpass123',
            email='charity@test.com', role='charity_admin'
        )
        # Create a charity
        self.charity = Charity.objects.create(
            admin=self.charity_admin,
            name='Test Charity',
            verified=True,
            description='A test charity',
            contact='+91-1234567890',
            location='Test City',
        )
        # Create a need request
        self.need = NeedRequest.objects.create(
            charity=self.charity,
            category='clothes',
            title='Winter Jackets',
            qty_needed=50,
            urgency=3,
            deadline=timezone.now() + timedelta(days=14),
        )


class AuthTests(BaseTestCase):
    """Test registration and JWT login."""

    def test_register_donor(self):
        resp = self.client.post('/api/auth/register/', {
            'username': 'new_donor',
            'password': 'securepass456',
            'email': 'new@example.com',
            'role': 'donor',
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['role'], 'donor')
        self.assertNotIn('password', resp.data)

    def test_register_charity_admin(self):
        resp = self.client.post('/api/auth/register/', {
            'username': 'new_admin',
            'password': 'securepass456',
            'email': 'admin@example.com',
            'role': 'charity_admin',
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['role'], 'charity_admin')

    def test_login_returns_jwt(self):
        resp = self.client.post('/api/auth/login/', {
            'username': 'test_donor',
            'password': 'testpass123',
        })
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn('access', resp.data)
        self.assertIn('refresh', resp.data)

    def test_login_wrong_password(self):
        resp = self.client.post('/api/auth/login/', {
            'username': 'test_donor',
            'password': 'wrongpassword',
        })
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)


class ProfileTests(BaseTestCase):
    """Test profile read/update."""

    def test_get_profile(self):
        self.client.force_authenticate(user=self.donor)
        resp = self.client.get('/api/users/profile/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['username'], 'test_donor')

    def test_patch_profile_location(self):
        self.client.force_authenticate(user=self.donor)
        resp = self.client.patch('/api/users/profile/', {'location': 'Mumbai'})
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['location'], 'Mumbai')

    def test_cannot_modify_give_coins_via_profile(self):
        self.client.force_authenticate(user=self.donor)
        resp = self.client.patch('/api/users/profile/', {'give_coins': 99999})
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        # give_coins should remain unchanged (read_only field)
        self.assertEqual(resp.data['give_coins'], 0)

    def test_profile_unauthenticated(self):
        resp = self.client.get('/api/users/profile/')
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)


class LeaderboardTests(BaseTestCase):
    """Test leaderboard endpoint."""

    def test_leaderboard_returns_donors(self):
        resp = self.client.get('/api/users/leaderboard/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIsInstance(resp.data, list)


class CharityTests(BaseTestCase):
    """Test charity CRUD."""

    def test_list_charities(self):
        resp = self.client.get('/api/charities/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

    def test_create_charity_as_admin(self):
        admin2 = User.objects.create_user(
            username='admin2', password='testpass123',
            email='admin2@test.com', role='charity_admin'
        )
        self.client.force_authenticate(user=admin2)
        resp = self.client.post('/api/charities/', {
            'name': 'New Charity',
            'description': 'Testing',
            'contact': '+91-0000000000',
            'location': 'Delhi',
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

    def test_donor_cannot_create_charity(self):
        self.client.force_authenticate(user=self.donor)
        resp = self.client.post('/api/charities/', {
            'name': 'Should Fail',
            'description': 'Testing',
        })
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)


class NeedRequestTests(BaseTestCase):
    """Test need request CRUD and filtering."""

    def test_list_all_needs(self):
        resp = self.client.get('/api/needs/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

    def test_list_needs_for_charity(self):
        resp = self.client.get(f'/api/charities/{self.charity.pk}/needs/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

    def test_create_need_as_charity_admin(self):
        self.client.force_authenticate(user=self.charity_admin)
        resp = self.client.post(f'/api/charities/{self.charity.pk}/needs/', {
            'category': 'food',
            'title': 'Rice Bags',
            'qty_needed': 100,
            'urgency': 4,
            'deadline': (timezone.now() + timedelta(days=7)).isoformat(),
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['qty_pledged'], 0)
        self.assertEqual(resp.data['status'], 'open')

    def test_donor_cannot_create_need(self):
        self.client.force_authenticate(user=self.donor)
        resp = self.client.post(f'/api/charities/{self.charity.pk}/needs/', {
            'category': 'food',
            'title': 'Should Fail',
            'qty_needed': 50,
        })
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)


class DonationTests(BaseTestCase):
    """Test donation pledging and validation."""

    def test_pledge_as_donor(self):
        self.client.force_authenticate(user=self.donor)
        resp = self.client.post('/api/donations/pledge/', {
            'need_request': self.need.pk,
            'qty': 5,
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        # Check qty_pledged was atomically incremented
        self.need.refresh_from_db()
        self.assertEqual(self.need.qty_pledged, 5)

    def test_pledge_exceeding_qty_needed(self):
        self.client.force_authenticate(user=self.donor)
        resp = self.client.post('/api/donations/pledge/', {
            'need_request': self.need.pk,
            'qty': 999,  # exceeds qty_needed of 50
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_charity_admin_cannot_pledge(self):
        self.client.force_authenticate(user=self.charity_admin)
        resp = self.client.post('/api/donations/pledge/', {
            'need_request': self.need.pk,
            'qty': 5,
        })
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_donation_history(self):
        self.client.force_authenticate(user=self.donor)
        # Create a donation first
        Donation.objects.create(donor=self.donor, need_request=self.need, qty=3)
        resp = self.client.get('/api/donations/history/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data), 1)

    def test_auto_fulfill_need_on_full_pledge(self):
        """When total pledges reach qty_needed, status should become 'fulfilled'."""
        self.client.force_authenticate(user=self.donor)
        self.client.post('/api/donations/pledge/', {
            'need_request': self.need.pk,
            'qty': 50,  # exactly qty_needed
        })
        self.need.refresh_from_db()
        self.assertEqual(self.need.status, 'fulfilled')


class GamificationTests(BaseTestCase):
    """Test GiveCoin awarding on donation status transition."""

    def test_coins_awarded_on_confirmation(self):
        # Create a donation
        donation = Donation.objects.create(
            donor=self.donor, need_request=self.need, qty=5
        )
        # Transition from pledged → confirmed (triggers gamification signal)
        donation.status = 'confirmed'
        donation.save()
        self.donor.refresh_from_db()
        # Expected: base=10*5=50, urgency=3, total=50*3=150
        self.assertEqual(self.donor.give_coins, 150)

    def test_fulfillment_bonus(self):
        """Bonus coins when donation completes the need."""
        # Set qty_pledged to 45 so 5 more will reach 50 (qty_needed)
        NeedRequest.objects.filter(pk=self.need.pk).update(qty_pledged=45)
        self.need.refresh_from_db()

        donation = Donation.objects.create(
            donor=self.donor, need_request=self.need, qty=5
        )
        donation.status = 'confirmed'
        donation.save()
        self.donor.refresh_from_db()
        # Expected: base=50, urgency=3, total=150 + 100 bonus = 250
        self.assertEqual(self.donor.give_coins, 250)


class BadgeTests(BaseTestCase):
    """Test badge listing and unlock."""

    def test_list_badges(self):
        Badge.objects.create(name='Test Badge', criteria_type='donation_count', criteria_value=1)
        resp = self.client.get('/api/badges/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

    def test_my_badges_authenticated(self):
        self.client.force_authenticate(user=self.donor)
        resp = self.client.get('/api/badges/mine/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

    def test_badge_auto_unlock(self):
        """Badge should be unlocked when criteria are met after coin award."""
        Badge.objects.create(
            name='First Steps', description='First confirmed donation',
            criteria_type='donation_count', criteria_value=1
        )
        donation = Donation.objects.create(
            donor=self.donor, need_request=self.need, qty=5
        )
        donation.status = 'confirmed'
        donation.save()
        self.assertEqual(UserBadge.objects.filter(user=self.donor).count(), 1)


class TeamTests(BaseTestCase):
    """Test team create/join/leave."""

    def test_create_team(self):
        self.client.force_authenticate(user=self.donor)
        resp = self.client.post('/api/teams/', {
            'name': 'Test Team',
            'challenge_goal': 100,
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        # Creator should be auto-added as member
        team = Team.objects.get(pk=resp.data['id'])
        self.assertIn(self.donor, team.members.all())

    def test_join_team(self):
        team = Team.objects.create(
            name='Joinable Team', creator=self.donor, challenge_goal=50
        )
        donor2 = User.objects.create_user(
            username='donor2', password='testpass123', role='donor'
        )
        self.client.force_authenticate(user=donor2)
        resp = self.client.post(f'/api/teams/{team.pk}/join/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn(donor2, team.members.all())

    def test_leave_team(self):
        # Create team with self.donor as creator (auto-added as member)
        team = Team.objects.create(
            name='Leavable Team', creator=self.donor, challenge_goal=50
        )
        team.members.add(self.donor)
        
        # Add another donor who will leave
        donor2 = User.objects.create_user(username='donor2_leave', password='pass', role='donor')
        team.members.add(donor2)
        
        self.client.force_authenticate(user=donor2)
        resp = self.client.post(f'/api/teams/{team.pk}/leave/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertNotIn(donor2, team.members.all())

    def test_creator_cannot_leave_team(self):
        team = Team.objects.create(name='Creator Team', creator=self.donor)
        team.members.add(self.donor)
        self.client.force_authenticate(user=self.donor)
        resp = self.client.post(f'/api/teams/{team.pk}/leave/')
        # Creators are blocked from leaving (they should delete instead)
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)


class ImpactUpdateTests(BaseTestCase):
    """Test impact update CRUD."""

    def test_list_impact_updates(self):
        resp = self.client.get('/api/impact-updates/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

    def test_create_impact_update_as_admin(self):
        donation = Donation.objects.create(
            donor=self.donor, need_request=self.need, qty=5
        )
        self.client.force_authenticate(user=self.charity_admin)
        resp = self.client.post('/api/impact-updates/', {
            'charity': self.charity.pk,
            'donation': donation.pk,
            'caption': 'Items delivered successfully!',
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

    def test_donor_cannot_create_impact_update(self):
        donation = Donation.objects.create(
            donor=self.donor, need_request=self.need, qty=5
        )
        self.client.force_authenticate(user=self.donor)
        resp = self.client.post('/api/impact-updates/', {
            'charity': self.charity.pk,
            'donation': donation.pk,
            'caption': 'Should fail',
        })
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)


class LogoutTests(BaseTestCase):
    """Test logout endpoint."""

    def test_logout_authenticated(self):
        self.client.force_authenticate(user=self.donor)
        resp = self.client.post('/api/auth/logout/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn('detail', resp.data)

    def test_logout_unauthenticated(self):
        resp = self.client.post('/api/auth/logout/')
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)


class DonationStatusTests(BaseTestCase):
    """Test PATCH /api/donations/<id>/status/ — charity admin confirms donations."""

    def setUp(self):
        super().setUp()
        self.donation = Donation.objects.create(
            donor=self.donor, need_request=self.need, qty=5
        )

    def test_charity_admin_confirms_donation(self):
        self.client.force_authenticate(user=self.charity_admin)
        resp = self.client.patch(
            f'/api/donations/{self.donation.pk}/status/',
            {'status': 'confirmed'},
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['status'], 'confirmed')

    def test_confirming_awards_give_coins(self):
        self.client.force_authenticate(user=self.charity_admin)
        self.client.patch(
            f'/api/donations/{self.donation.pk}/status/',
            {'status': 'confirmed'},
        )
        self.donor.refresh_from_db()
        # base=10*5=50, urgency=3, total=150
        self.assertEqual(self.donor.give_coins, 150)

    def test_charity_admin_marks_received(self):
        # Transition to confirmed first
        self.donation.status = 'confirmed'
        self.donation.save()
        self.client.force_authenticate(user=self.charity_admin)
        resp = self.client.patch(
            f'/api/donations/{self.donation.pk}/status/',
            {'status': 'received'},
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['status'], 'received')

    def test_invalid_status_transition(self):
        """Cannot jump from pledged directly to received."""
        self.client.force_authenticate(user=self.charity_admin)
        resp = self.client.patch(
            f'/api/donations/{self.donation.pk}/status/',
            {'status': 'received'},
        )
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_donor_cannot_update_status(self):
        self.client.force_authenticate(user=self.donor)
        resp = self.client.patch(
            f'/api/donations/{self.donation.pk}/status/',
            {'status': 'confirmed'},
        )
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_wrong_charity_admin_cannot_update(self):
        """A charity admin from a different charity cannot update this donation."""
        other_admin = User.objects.create_user(
            username='other_admin', password='testpass123',
            email='other@test.com', role='charity_admin'
        )
        self.client.force_authenticate(user=other_admin)
        resp = self.client.patch(
            f'/api/donations/{self.donation.pk}/status/',
            {'status': 'confirmed'},
        )
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)


class TeamLeaderboardTests(BaseTestCase):
    """Test GET /api/teams/<id>/leaderboard/"""

    def test_team_leaderboard(self):
        team = Team.objects.create(
            name='Leaderboard Team', creator=self.donor, challenge_goal=50
        )
        donor2 = User.objects.create_user(
            username='donor2', password='testpass123', role='donor', give_coins=500
        )
        team.members.add(self.donor, donor2)
        resp = self.client.get(f'/api/teams/{team.pk}/leaderboard/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        # donor2 has more coins, should appear first
        self.assertEqual(resp.data[0]['username'], 'donor2')


class CharityPledgesTests(BaseTestCase):
    """Test GET /api/charities/pledges/ — charity admin sees all pledges."""

    def test_charity_admin_sees_pledges(self):
        Donation.objects.create(donor=self.donor, need_request=self.need, qty=3)
        self.client.force_authenticate(user=self.charity_admin)
        resp = self.client.get('/api/charities/pledges/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data), 1)

    def test_donor_cannot_access_charity_pledges(self):
        self.client.force_authenticate(user=self.donor)
        resp = self.client.get('/api/charities/pledges/')
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)


class StreakTests(BaseTestCase):
    """Test streak_days update on donation confirmation."""

    def test_streak_starts_at_one_on_first_confirmed_donation(self):
        donation = Donation.objects.create(
            donor=self.donor, need_request=self.need, qty=2
        )
        donation.status = 'confirmed'
        donation.save()
        self.donor.refresh_from_db()
        self.assertEqual(self.donor.streak_days, 1)

    def test_last_donation_date_set_on_confirmation(self):
        from django.utils import timezone
        donation = Donation.objects.create(
            donor=self.donor, need_request=self.need, qty=2
        )
        donation.status = 'confirmed'
        donation.save()
        self.donor.refresh_from_db()
        self.assertEqual(self.donor.last_donation_date, timezone.now().date())

    def test_same_day_donation_preserves_streak(self):
        from django.utils import timezone
        # Simulate donor already donated today
        today = timezone.now().date()
        self.donor.streak_days = 3
        self.donor.last_donation_date = today
        self.donor.save()

        donation = Donation.objects.create(
            donor=self.donor, need_request=self.need, qty=2
        )
        donation.status = 'confirmed'
        donation.save()
        self.donor.refresh_from_db()
        self.assertEqual(self.donor.streak_days, 3)  # unchanged
