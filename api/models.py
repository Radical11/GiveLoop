from django.db import models
from django.db.models import F, Q, CheckConstraint, UniqueConstraint
from django.contrib.auth.models import AbstractUser
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
import datetime

class User(AbstractUser):
    ROLE_CHOICES = (
        ('donor', 'Donor'),
        ('charity_admin', 'Charity Admin'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='donor')
    give_coins = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    streak_days = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    location = models.CharField(max_length=255, blank=True, null=True)
    last_donation_date = models.DateField(blank=True, null=True)

def one_week_hence():
    return timezone.now() + datetime.timedelta(days=7)

class Charity(models.Model):
    admin = models.OneToOneField(User, on_delete=models.CASCADE, related_name='charity_profile')
    name = models.CharField(max_length=255, unique=True)
    verified = models.BooleanField(default=False)
    description = models.TextField(default='')
    contact = models.CharField(max_length=255, default='')
    location = models.CharField(max_length=255, default='')

    class Meta:
        verbose_name_plural = "Charities"
        ordering = ['name']

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
    qty_needed = models.IntegerField(validators=[MinValueValidator(1)])
    # strictly regulated by logic, read-only for clients
    qty_pledged = models.IntegerField(default=0, validators=[MinValueValidator(0)]) 
    urgency = models.IntegerField(default=1, validators=[MinValueValidator(1), MaxValueValidator(5)])
    deadline = models.DateTimeField(default=one_week_hence)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')

    class Meta:
        constraints = [
            CheckConstraint(
                check=Q(qty_pledged__lte=F('qty_needed')),
                name='qty_pledged_lte_qty_needed'
            ),
            CheckConstraint(
                check=Q(qty_pledged__gte=0),
                name='qty_pledged_non_negative'
            )
        ]
        ordering = ['-urgency', 'deadline']

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
    qty = models.IntegerField(validators=[MinValueValidator(1)])
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pledged')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.qty}x {self.need_request.title} by {self.donor.username}"

class ImpactUpdate(models.Model):
    charity = models.ForeignKey(Charity, on_delete=models.CASCADE, related_name='impact_updates')
    donation = models.ForeignKey(Donation, on_delete=models.CASCADE, related_name='impact_updates')
    photo = models.ImageField(upload_to='impact_photos/', blank=True, null=True)
    caption = models.TextField(default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

class Team(models.Model):
    name = models.CharField(max_length=255, unique=True)
    creator = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_teams')
    members = models.ManyToManyField(User, related_name='teams')
    challenge_goal = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    challenge_deadline = models.DateTimeField(default=one_week_hence)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name

class Badge(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)
    icon = models.URLField(blank=True, null=True)
    criteria_type = models.CharField(max_length=100, choices=(
        ('donation_count', 'Donation Count'),
        ('coin_threshold', 'Coin Threshold'),
        ('streak_days', 'Streak Days'),
    ))
    criteria_value = models.IntegerField(default=0, validators=[MinValueValidator(1)])

    class Meta:
        ordering = ['criteria_value']

    def __str__(self):
        return self.name

class UserBadge(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='earned_badges')
    badge = models.ForeignKey(Badge, on_delete=models.CASCADE, related_name='awarded_to')
    earned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            UniqueConstraint(fields=['user', 'badge'], name='unique_user_badge')
        ]
        ordering = ['-earned_at']

