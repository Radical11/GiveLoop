"""
Phase 7: Management command to populate the database with realistic demo data.

Usage:
    python manage.py seed_data          # seeds everything
    python manage.py seed_data --flush  # clears existing data first

Creates:
  - 2 Charity Admin users + their Charity profiles
  - 5 Donor users
  - 10 NeedRequests across both charities
  - 15 Donations (some confirmed/received to trigger gamification)
  - 6 Badges (donation_count + coin_threshold + streak_days)
  - 2 Teams with members
  - 3 ImpactUpdates
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta

from api.models import (
    Charity, NeedRequest, Donation, ImpactUpdate,
    Team, Badge, UserBadge,
)

User = get_user_model()


class Command(BaseCommand):
    help = "Seed the database with realistic demo data for GiveLoop."

    def add_arguments(self, parser):
        parser.add_argument(
            "--flush",
            action="store_true",
            help="Delete all existing seeded data before creating new data.",
        )

    def handle(self, *args, **options):
        if options["flush"]:
            self.stdout.write(self.style.WARNING("Flushing existing data..."))
            UserBadge.objects.all().delete()
            Badge.objects.all().delete()
            ImpactUpdate.objects.all().delete()
            Donation.objects.all().delete()
            NeedRequest.objects.all().delete()
            Team.objects.all().delete()
            Charity.objects.all().delete()
            User.objects.filter(is_superuser=False).delete()
            self.stdout.write(self.style.SUCCESS("Flushed."))

        self.stdout.write("Creating users...")
        # ── Charity Admins ──────────────────────────────────────────
        ca1 = self._create_user("hopeorg_admin", "hope@giveloop.org", "charity_admin")
        ca2 = self._create_user("greenearth_admin", "green@giveloop.org", "charity_admin")

        # ── Donors ──────────────────────────────────────────────────
        donors = [
            self._create_user("alice_donor", "alice@example.com", "donor"),
            self._create_user("bob_donor", "bob@example.com", "donor"),
            self._create_user("carol_donor", "carol@example.com", "donor"),
            self._create_user("dave_donor", "dave@example.com", "donor"),
            self._create_user("eve_donor", "eve@example.com", "donor"),
        ]

        self.stdout.write("Creating charities...")
        c1, _ = Charity.objects.get_or_create(
            admin=ca1,
            defaults={
                "name": "Hope Foundation",
                "verified": True,
                "description": "Providing essential supplies to underprivileged communities across South Asia.",
                "contact": "+91-9876543210",
                "location": "Mumbai, India",
            },
        )
        c2, _ = Charity.objects.get_or_create(
            admin=ca2,
            defaults={
                "name": "GreenEarth Trust",
                "verified": True,
                "description": "Environmental charity focused on reforestation and eco-education programs.",
                "contact": "+91-8765432109",
                "location": "Bangalore, India",
            },
        )

        self.stdout.write("Creating need requests...")
        now = timezone.now()
        needs_data = [
            # (charity, category, title, qty_needed, urgency, days_until_deadline)
            (c1, "clothes", "Winter Jackets for Children", 50, 5, 14),
            (c1, "food", "Rice Bags (10kg) for Families", 100, 4, 7),
            (c1, "books", "School Textbooks – Grade 5", 200, 3, 30),
            (c1, "toys", "Soft Toys for Toddler Ward", 80, 2, 21),
            (c1, "electronics", "Refurbished Tablets for Education", 30, 5, 10),
            (c2, "food", "Organic Seed Packets for Farmers", 500, 3, 45),
            (c2, "books", "Environmental Science Workbooks", 150, 2, 30),
            (c2, "clothes", "Eco-Friendly Tote Bags", 300, 1, 60),
            (c2, "electronics", "Solar-Powered Lanterns", 60, 4, 15),
            (c2, "toys", "Wooden Educational Puzzles", 120, 3, 25),
        ]
        needs = []
        for charity, cat, title, qty, urg, days in needs_data:
            nr, _ = NeedRequest.objects.get_or_create(
                charity=charity,
                title=title,
                defaults={
                    "category": cat,
                    "qty_needed": qty,
                    "urgency": urg,
                    "deadline": now + timedelta(days=days),
                    "status": "open",
                },
            )
            needs.append(nr)

        self.stdout.write("Creating donations...")
        donations_data = [
            # (donor_index, need_index, qty, status)
            (0, 0, 10, "confirmed"),
            (1, 0, 5, "pledged"),
            (2, 1, 20, "received"),
            (0, 1, 15, "confirmed"),
            (3, 2, 50, "pledged"),
            (4, 2, 30, "confirmed"),
            (1, 3, 20, "pledged"),
            (2, 4, 5, "confirmed"),
            (3, 5, 100, "pledged"),
            (0, 6, 40, "confirmed"),
            (4, 7, 50, "pledged"),
            (1, 8, 15, "received"),
            (3, 9, 25, "confirmed"),
            (2, 0, 8, "pledged"),
            (4, 1, 10, "confirmed"),
        ]
        created_donations = []
        for d_idx, n_idx, qty, final_status in donations_data:
            don, created = Donation.objects.get_or_create(
                donor=donors[d_idx],
                need_request=needs[n_idx],
                qty=qty,
                defaults={"status": final_status},
            )
            if created and final_status != "pledged":
                # Manually set status without triggering signal cascade again
                Donation.objects.filter(pk=don.pk).update(status=final_status)
                don.refresh_from_db()
            created_donations.append(don)

        self.stdout.write("Creating badges...")
        badges_data = [
            ("First Steps", "Make your first confirmed donation", "donation_count", 1),
            ("Helping Hand", "Complete 5 confirmed donations", "donation_count", 5),
            ("Generous Soul", "Complete 10 confirmed donations", "donation_count", 10),
            ("Coin Collector", "Earn 500 GiveCoins", "coin_threshold", 500),
            ("GiveCoin Master", "Earn 2000 GiveCoins", "coin_threshold", 2000),
            ("Streak Star", "Maintain a 7-day giving streak", "streak_days", 7),
        ]
        for name, desc, ctype, cval in badges_data:
            Badge.objects.get_or_create(
                name=name,
                defaults={
                    "description": desc,
                    "criteria_type": ctype,
                    "criteria_value": cval,
                },
            )

        self.stdout.write("Creating teams...")
        t1, _ = Team.objects.get_or_create(
            name="Mumbai Givers",
            defaults={
                "creator": donors[0],
                "challenge_goal": 100,
                "challenge_deadline": now + timedelta(days=30),
            },
        )
        t1.members.add(donors[0], donors[1], donors[2])

        t2, _ = Team.objects.get_or_create(
            name="Green Warriors",
            defaults={
                "creator": donors[3],
                "challenge_goal": 200,
                "challenge_deadline": now + timedelta(days=45),
            },
        )
        t2.members.add(donors[3], donors[4])

        self.stdout.write("Creating impact updates...")
        confirmed_donations = [d for d in created_donations if d.status in ("confirmed", "received")]
        for don in confirmed_donations[:3]:
            ImpactUpdate.objects.get_or_create(
                charity=don.need_request.charity,
                donation=don,
                defaults={
                    "caption": f"Thank you {don.donor.username}! Your donation of {don.qty}x "
                               f"{don.need_request.title} has arrived and is being distributed.",
                },
            )

        self.stdout.write(self.style.SUCCESS(
            f"\n✅ Seed complete!\n"
            f"   Users:         {User.objects.filter(is_superuser=False).count()}\n"
            f"   Charities:     {Charity.objects.count()}\n"
            f"   Need Requests: {NeedRequest.objects.count()}\n"
            f"   Donations:     {Donation.objects.count()}\n"
            f"   Badges:        {Badge.objects.count()}\n"
            f"   Teams:         {Team.objects.count()}\n"
            f"   Impact Updates:{ImpactUpdate.objects.count()}\n"
            f"\n   Default password for all seeded users: giveloop2026"
        ))

    def _create_user(self, username, email, role):
        """Create a user with a safe default password, or return existing."""
        user, created = User.objects.get_or_create(
            username=username,
            defaults={
                "email": email,
                "role": role,
                "location": "India",
            },
        )
        if created:
            user.set_password("giveloop2026")
            user.save()
        return user
