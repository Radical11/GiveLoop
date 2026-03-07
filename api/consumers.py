"""
Phase 6: WebSocket Consumer for Real-Time Need Progress Updates

Connects Flutter/Android clients to receive live updates when
NeedRequest.qty_pledged changes (i.e. new donations come in).
"""
import json

from channels.generic.websocket import AsyncWebsocketConsumer


class NeedProgressConsumer(AsyncWebsocketConsumer):
    """
    WebSocket endpoint: ws/needs/<int:need_id>/progress/

    On connect, the client joins a channel group named "needs_{need_id}".
    Whenever the signals layer fires a group_send with type="progress_update",
    this consumer pushes the data to every connected client in real time.
    """

    async def connect(self):
        self.need_id = self.scope["url_route"]["kwargs"]["need_id"]
        self.group_name = f"needs_{self.need_id}"

        # Join the need-specific broadcast group
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        # Leave the broadcast group
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def progress_update(self, event):
        """
        Handler for messages with type="progress_update".
        Broadcasts live qty_pledged / qty_needed to all connected clients.
        """
        await self.send(text_data=json.dumps({
            "qty_pledged": event["qty_pledged"],
            "qty_needed": event["qty_needed"],
        }))
