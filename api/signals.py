"""
Phase 4: Business Logic & Anti-Loophole Signals
- Safe pledge quantity increments using DB-level F() expressions + atomic transactions
  to prevent race conditions when multiple donors pledge at the same time.
- GiveCoin Gamification Rules Engine: awards coins on donation confirmation/receipt.
- WebSocket broadcast trigger on successful qty_pledged changes.
"""
from django.db import transaction
from django.db.models import F
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from django.utils import timezone
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

from .models import Donation, NeedRequest, UserBadge, Badge


# ---------------------------------------------------------------------------
# 4.1 Safe Donation Pledging (Race-Condition-Safe)
# ---------------------------------------------------------------------------
@receiver(post_save, sender=Donation)
def handle_donation_save(sender, instance, created, **kwargs):
    """
    When a new Donation is CREATED (status='pledged'):
      - Atomically increment NeedRequest.qty_pledged using F() expression so
        concurrent requests never double-count.
      - Auto-mark NeedRequest as 'fulfilled' when fully pledged.

    When a Donation status transitions to 'confirmed' or 'received':
      - Award GiveCoins to the donor (gamification engine).
      - Check & unlock badges.
      - Broadcast WebSocket update for real-time progress.
    """
    if created:
        # Atomically increment qty_pledged — safe under concurrent requests
        with transaction.atomic():
            NeedRequest.objects.filter(pk=instance.need_request_id).update(
                qty_pledged=F('qty_pledged') + instance.qty
            )
            # Refresh to get the new value and check fulfilment
            need_request = NeedRequest.objects.select_for_update().get(pk=instance.need_request_id)
            if need_request.qty_pledged >= need_request.qty_needed:
                need_request.status = 'fulfilled'
                need_request.save(update_fields=['status'])

        # Broadcast real-time WebSocket update to Flutter clients
        _broadcast_progress(need_request)


# ---------------------------------------------------------------------------
# 4.2 Gamification Rules Engine (GiveCoins Engine)
# ---------------------------------------------------------------------------
_PREVIOUS_STATUSES = {}  # lightweight in-process tracker for status transitions

@receiver(pre_save, sender=Donation)
def track_previous_donation_status(sender, instance, **kwargs):
    """Cache the prior status so post_save can detect transitions."""
    if instance.pk:
        try:
            _PREVIOUS_STATUSES[instance.pk] = Donation.objects.get(pk=instance.pk).status
        except Donation.DoesNotExist:
            pass


@receiver(post_save, sender=Donation)
def award_give_coins(sender, instance, created, **kwargs):
    """
    GiveCoin Award Logic (fires when a Donation is confirmed or received):
      - Base coins : 10 per item donated
      - Urgency multiplier: urgency level (1-5) applied as multiplier
      - Fulfilment bonus: +100 bonus coins if this donation completes the NeedRequest
    """
    if created:
        return  # already handled in handle_donation_save

    prev_status = _PREVIOUS_STATUSES.pop(instance.pk, None)
    if prev_status in ('pledged',) and instance.status in ('confirmed', 'received'):
        need_request = instance.need_request
        need_request.refresh_from_db()  # ensure we have latest qty_pledged after F() update
        donor = instance.donor

        # Base coins
        base_coins = 10 * instance.qty

        # Urgency multiplier (urgency stored as 1-5 integer)
        urgency_multiplier = need_request.urgency  # e.g. 5 for urgent
        total_coins = base_coins * urgency_multiplier

        # Fulfilment bonus — was this donation the one that topped it off?
        if need_request.qty_pledged >= need_request.qty_needed:
            total_coins += 100

        # Atomically add coins and update streak — prevents concurrent balance corruption
        today = timezone.now().date()
        User = get_user_model()
        donor.refresh_from_db()
        last_date = donor.last_donation_date
        if last_date is None or (today - last_date).days > 1:
            new_streak = 1  # first donation or streak broken
        elif (today - last_date).days == 1:
            new_streak = donor.streak_days + 1  # consecutive day
        else:
            new_streak = donor.streak_days  # same day — preserve streak

        with transaction.atomic():
            User.objects.filter(pk=donor.pk).update(
                give_coins=F('give_coins') + total_coins,
                streak_days=new_streak,
                last_donation_date=today,
            )

        # Check badge unlocks after coin update
        _check_and_award_badges(donor)

        # Broadcast updated progress (status change)
        _broadcast_progress(need_request)


# ---------------------------------------------------------------------------
# 4.3 Badge Unlock Logic
# ---------------------------------------------------------------------------
BADGE_CRITERIA_DISPATCH = {
    'donation_count': lambda donor: donor.donations.filter(status__in=['confirmed', 'received']).count(),
    'coin_threshold': lambda donor: donor.give_coins,
    'streak_days': lambda donor: donor.streak_days,
}

def _check_and_award_badges(donor):
    """Evaluate all badges and unlock any newly earned ones for the donor."""
    donor.refresh_from_db()
    already_earned = set(donor.user_badges.values_list('badge_id', flat=True))
    all_badges = Badge.objects.exclude(pk__in=already_earned)

    for badge in all_badges:
        criteria_fn = BADGE_CRITERIA_DISPATCH.get(badge.criteria_type)
        if criteria_fn and criteria_fn(donor) >= badge.criteria_value:
            UserBadge.objects.create(user=donor, badge=badge)


# ---------------------------------------------------------------------------
# 4.3 WebSocket Broadcast Helper
# ---------------------------------------------------------------------------
def _broadcast_progress(need_request):
    """
    Emit a real-time WebSocket message to Flutter clients listening on
    ws://...needs/<id>/progress/ so the LinearProgressIndicator updates live.
    """
    channel_layer = get_channel_layer()
    if channel_layer is None:
        return  # No channel layer configured (e.g. during tests)

    group_name = f"needs_{need_request.pk}"
    async_to_sync(channel_layer.group_send)(
        group_name,
        {
            "type": "progress_update",
            "qty_pledged": need_request.qty_pledged,
            "qty_needed": need_request.qty_needed,
        }
    )
