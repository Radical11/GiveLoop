from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    ROLE_CHOICES = (
        ('donor', 'Donor'),
        ('charity_admin', 'Charity Admin'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='donor')
    give_coins = models.IntegerField(default=0)
    streak_days = models.IntegerField(default=0)
    location = models.CharField(max_length=255, blank=True, null=True)
    last_donation_date = models.DateField(blank=True, null=True)

class Charity(models.Model):
    admin = models.OneToOneField(User, on_delete=models.CASCADE, related_name='charity_profile')
    name = models.CharField(max_length=255)
    verified = models.BooleanField(default=False)
    description = models.TextField(blank=True, null=True)
    contact = models.CharField(max_length=255, blank=True, null=True)
    location = models.CharField(max_length=255, blank=True, null=True)

    def __str__(self):
        return self.name

class NeedRequest(models.Model):
    STATUS_CHOICES = (
        ('open', 'Open'),
        ('fulfilled', 'Fulfilled'),
        ('closed', 'Closed')
    )
    charity = models.ForeignKey(Charity, on_delete=models.CASCADE, related_name='need_requests')
    category = models.CharField(max_length=100)
    title = models.CharField(max_length=255)
    qty_needed = models.IntegerField()
    # strictly regulated by logic, read-only for clients
    qty_pledged = models.IntegerField(default=0) 
    urgency = models.IntegerField(default=1) # 1-5 scale
    deadline = models.DateTimeField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')

    def __str__(self):
        return f"{self.title} ({self.charity.name})"

class Donation(models.Model):
    STATUS_CHOICES = (
        ('pledged', 'Pledged'),
        ('confirmed', 'Confirmed'),
        ('received', 'Received')
    )
    donor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='donations')
    need_request = models.ForeignKey(NeedRequest, on_delete=models.CASCADE, related_name='donations')
    qty = models.IntegerField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pledged')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.qty}x {self.need_request.title} by {self.donor.username}"

class ImpactUpdate(models.Model):
    charity = models.ForeignKey(Charity, on_delete=models.CASCADE, related_name='impact_updates')
    donation = models.ForeignKey(Donation, on_delete=models.CASCADE, related_name='impact_updates')
    photo = models.ImageField(upload_to='impact_photos/', blank=True, null=True)
    caption = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

class Team(models.Model):
    name = models.CharField(max_length=255)
    creator = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_teams')
    members = models.ManyToManyField(User, related_name='teams')
    challenge_goal = models.IntegerField(default=0)
    challenge_deadline = models.DateTimeField(blank=True, null=True)

    def __str__(self):
        return self.name

class Badge(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    icon = models.URLField(blank=True, null=True)
    criteria_type = models.CharField(max_length=100)
    criteria_value = models.IntegerField(default=0)

    def __str__(self):
        return self.name

class UserBadge(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_badges')
    badge = models.ForeignKey(Badge, on_delete=models.CASCADE, related_name='user_badges')
    earned_at = models.DateTimeField(auto_now_add=True)

