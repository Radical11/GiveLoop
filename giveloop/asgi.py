"""
ASGI config for giveloop project.

Wires up both HTTP and WebSocket protocols:
  - HTTP  → standard Django ASGI application
  - WS    → Django Channels URLRouter for real-time consumers
"""
import os

from channels.auth import AuthMiddlewareStack
from channels.routing import ProtocolTypeRouter, URLRouter
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'giveloop.settings')

# Initialize Django before importing routing (models need to be ready)
django_asgi_app = get_asgi_application()

from api.routing import websocket_urlpatterns  # noqa: E402

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": AuthMiddlewareStack(
        URLRouter(websocket_urlpatterns)
    ),
})
