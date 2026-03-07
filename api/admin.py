from django.contrib import admin
from .models import User, Charity, NeedRequest, Donation, ImpactUpdate, Team, Badge, UserBadge

admin.site.register(User)
admin.site.register(Charity)
admin.site.register(NeedRequest)
admin.site.register(Donation)
admin.site.register(ImpactUpdate)
admin.site.register(Team)
admin.site.register(Badge)
admin.site.register(UserBadge)

