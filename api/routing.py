"""
Phase 6: WebSocket URL routing for the api app.
Maps ws/needs/<int:need_id>/progress/ to the NeedProgressConsumer.
"""
from django.urls import re_path

from . import consumers

websocket_urlpatterns = [
    re_path(r"ws/needs/(?P<need_id>\d+)/progress/$", consumers.NeedProgressConsumer.as_asgi()),
]
