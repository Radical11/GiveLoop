from django.db.models.signals import post_save, pre_save, post_delete
from django.dispatch import receiver
from django.db import transaction
from django.db.models import F
from django.utils import timezone
from django.contrib.auth import get_user_model
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from rest_framework.serializers import ValidationError

from .models import Donation, NeedRequest, Badge, UserBadge

User = get_user_model()

@receiver(post_save, sender=Donation)
def handle_donation_save(sender, instance, created, **kwargs):
    """Increment qty_pledged atomically on new donation."""
    if created:
        with transaction.atomic():
            # Lock the NeedRequest to prevent over-pledging
            need_request = NeedRequest.objects.select_for_update().get(pk=instance.need_request_id)
            
            if need_request.qty_pledged + instance.qty > need_request.qty_needed:
                # Critical safety net
                raise ValidationError("This donation would exceed the required quantity.")

            # Atomically increment
            NeedRequest.objects.filter(pk=need_request.pk).update(
                qty_pledged=F('qty_pledged') + instance.qty
            )
            
            # Re-fetch for status and broadcast
            need_request.refresh_from_db()
            if need_request.qty_pledged >= need_request.qty_needed and need_request.status == 'open':
                need_request.status = 'fulfilled'
                need_request.save(update_fields=['status'])
        
        _broadcast_progress(need_request)

@receiver(post_delete, sender=Donation)
def handle_donation_delete(sender, instance, **kwargs):
    """Restore qty_pledged when a donation is deleted."""
    with transaction.atomic():
        NeedRequest.objects.filter(pk=instance.need_request_id).update(
            qty_pledged=F('qty_pledged') - instance.qty
        )
        need_request = NeedRequest.objects.get(pk=instance.need_request_id)
        if need_request.qty_pledged < need_request.qty_needed and need_request.status == 'fulfilled':
             need_request.status = 'open'
             need_request.save(update_fields=['status'])
             
    _broadcast_progress(need_request)

_STATUS_CACHE = {}

@receiver(pre_save, sender=Donation)
def track_donation_status_change(sender, instance, **kwargs):
    if instance.pk:
        try:
            _STATUS_CACHE[instance.pk] = Donation.objects.get(pk=instance.pk).status
        except Donation.DoesNotExist:
            pass

@receiver(post_save, sender=Donation)
def award_give_coins(sender, instance, created, **kwargs):
    """Award coins on confirmation/receipt using direct urgency multiplier."""
    if created:
        return

    old_status = _STATUS_CACHE.pop(instance.pk, None)
    if old_status == 'pledged' and instance.status in ('confirmed', 'received'):
        need_request = instance.need_request
        # IMPORTANT: refresh from DB to get the latest qty_pledged after F() update
        need_request.refresh_from_db()
        donor = instance.donor
        
        # Base: 10 per qty * urgency level (1-5 simple multiplier)
        base = 10 * instance.qty
        total = base * need_request.urgency
        
        # Bonus if the donation fulfills the need request
        if need_request.qty_pledged >= need_request.qty_needed:
            total += 100
            
        with transaction.atomic():
            # Update user atomically
            u = User.objects.select_for_update().get(pk=donor.pk)
            
            # Simple streak logic: if yesterday was the last donation date, increment
            today = timezone.now().date()
            if u.last_donation_date == today:
                # Already donated today, don't increment streak but award coins
                pass
            elif u.last_donation_date == today - timezone.timedelta(days=1):
                u.streak_days = F('streak_days') + 1
            else:
                u.streak_days = 1
            
            u.give_coins = F('give_coins') + total
            u.last_donation_date = today
            u.save()
            
            # Evaluate badges
            _check_and_award_badges(u)
            
        _broadcast_progress(need_request)

def _check_and_award_badges(donor):
    """Check and grant badges based on current stats."""
    donor.refresh_from_db()
    
    # Calc stats
    donations_confirmed = donor.donations.filter(status__in=['confirmed', 'received']).count()
    coins = donor.give_coins
    streak = donor.streak_days
    
    # Use 'earned_badges' reverse relation from models.py
    already_earned = set(donor.earned_badges.values_list('badge_id', flat=True))
    eligible_badges = Badge.objects.exclude(pk__in=already_earned)
    
    for badge in eligible_badges:
        earned = False
        if badge.criteria_type == 'donation_count' and donations_confirmed >= badge.criteria_value:
            earned = True
        elif badge.criteria_type == 'coin_threshold' and coins >= badge.criteria_value:
            earned = True
        elif badge.criteria_type == 'streak_days' and streak >= badge.criteria_value:
            earned = True
            
        if earned:
            UserBadge.objects.get_or_create(user=donor, badge=badge)

def _broadcast_progress(need_request):
    """WebSocket notification for real-time progress bar."""
    channel_layer = get_channel_layer()
    if not channel_layer:
        return
        
    group_name = f"needs_{need_request.id}"
    async_to_sync(channel_layer.group_send)(
        group_name,
        {
            "type": "progress_update",
            "qty_pledged": need_request.qty_pledged,
            "qty_needed": need_request.qty_needed,
            "status": need_request.status
        }
    )
