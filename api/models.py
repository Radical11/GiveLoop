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
