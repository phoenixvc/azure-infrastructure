"""In-memory message broker implementation for development and testing."""

import asyncio
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Set
from uuid import UUID

from .base import (
    BaseMessageBroker,
    Message,
    MessageHandler,
    MessageStatus,
    MessageBrokerHealth,
)


@dataclass
class QueueConfig:
    """Queue configuration."""

    max_delivery_count: int = 10
    lock_duration: timedelta = timedelta(minutes=1)


class InMemoryMessageBroker(BaseMessageBroker, MessageBrokerHealth):
    """In-memory message broker implementation.

    Suitable for:
    - Local development
    - Unit testing
    - Single-instance deployments

    Not suitable for:
    - Production multi-instance deployments
    - Persistent messaging
    - High-throughput scenarios

    Example:
        ```python
        broker = InMemoryMessageBroker()
        await broker.create_queue("orders")

        message = Message(body='{"order_id": 123}')
        await broker.send_to_queue("orders", message)

        messages = await broker.receive_from_queue("orders")
        for msg in messages:
            # Process message
            await broker.complete_message("orders", msg)
        ```
    """

    def __init__(self):
        self._queues: Dict[str, List[Message]] = defaultdict(list)
        self._dead_letters: Dict[str, List[Message]] = defaultdict(list)
        self._topics: Dict[str, Dict[str, List[Message]]] = defaultdict(
            lambda: defaultdict(list)
        )
        self._subscriptions: Dict[str, Dict[str, MessageHandler]] = defaultdict(dict)
        self._queue_configs: Dict[str, QueueConfig] = {}
        self._processing: Dict[str, Set[UUID]] = defaultdict(set)

    # --- Queue Operations ---

    async def send_to_queue(
        self,
        queue: str,
        message: Message,
        delay: Optional[timedelta] = None,
    ) -> bool:
        if delay:
            message.scheduled_at = datetime.utcnow() + delay
        message.enqueued_at = datetime.utcnow()
        message.status = MessageStatus.PENDING
        self._queues[queue].append(message)
        return True

    async def send_batch_to_queue(
        self,
        queue: str,
        messages: List[Message],
    ) -> int:
        count = 0
        for message in messages:
            if await self.send_to_queue(queue, message):
                count += 1
        return count

    async def receive_from_queue(
        self,
        queue: str,
        max_messages: int = 1,
        timeout: Optional[timedelta] = None,
    ) -> List[Message]:
        received = []
        now = datetime.utcnow()

        # Filter out scheduled messages not yet ready
        available = [
            msg
            for msg in self._queues[queue]
            if msg.id not in self._processing[queue]
            and (msg.scheduled_at is None or msg.scheduled_at <= now)
        ]

        for message in available[:max_messages]:
            message.delivery_count += 1
            message.status = MessageStatus.PROCESSING
            self._processing[queue].add(message.id)
            received.append(message)

        return received

    async def complete_message(self, queue: str, message: Message) -> bool:
        if message.id in self._processing[queue]:
            self._processing[queue].discard(message.id)
            self._queues[queue] = [
                m for m in self._queues[queue] if m.id != message.id
            ]
            message.status = MessageStatus.COMPLETED
            return True
        return False

    async def abandon_message(self, queue: str, message: Message) -> bool:
        if message.id in self._processing[queue]:
            self._processing[queue].discard(message.id)
            message.status = MessageStatus.PENDING

            # Check if max delivery count exceeded
            config = self._queue_configs.get(queue, QueueConfig())
            if message.delivery_count >= config.max_delivery_count:
                await self.dead_letter_message(
                    queue, message, "Max delivery count exceeded"
                )

            return True
        return False

    async def dead_letter_message(
        self,
        queue: str,
        message: Message,
        reason: str,
    ) -> bool:
        self._processing[queue].discard(message.id)
        self._queues[queue] = [m for m in self._queues[queue] if m.id != message.id]
        message.status = MessageStatus.DEAD_LETTERED
        message.properties["dead_letter_reason"] = reason
        self._dead_letters[queue].append(message)
        return True

    # --- Topic/Subscription Operations ---

    async def publish_to_topic(
        self,
        topic: str,
        message: Message,
    ) -> bool:
        message.enqueued_at = datetime.utcnow()

        # Deliver to all subscriptions
        for subscription, handler in self._subscriptions[topic].items():
            msg_copy = Message(
                id=message.id,
                body=message.body,
                content_type=message.content_type,
                correlation_id=message.correlation_id,
                properties=dict(message.properties),
                enqueued_at=message.enqueued_at,
            )
            self._topics[topic][subscription].append(msg_copy)

            # Trigger handler if registered
            try:
                await handler(msg_copy)
            except Exception:
                pass  # Handler errors don't affect publishing

        return True

    async def subscribe(
        self,
        topic: str,
        subscription: str,
        handler: MessageHandler,
    ) -> None:
        self._subscriptions[topic][subscription] = handler

    async def unsubscribe(
        self,
        topic: str,
        subscription: str,
    ) -> bool:
        if subscription in self._subscriptions[topic]:
            del self._subscriptions[topic][subscription]
            return True
        return False

    # --- Queue Management ---

    async def create_queue(
        self,
        queue: str,
        max_delivery_count: int = 10,
        lock_duration: timedelta = timedelta(minutes=1),
    ) -> bool:
        self._queue_configs[queue] = QueueConfig(
            max_delivery_count=max_delivery_count,
            lock_duration=lock_duration,
        )
        # Ensure queue exists (defaultdict handles this)
        _ = self._queues[queue]
        return True

    async def delete_queue(self, queue: str) -> bool:
        if queue in self._queues:
            del self._queues[queue]
            self._queue_configs.pop(queue, None)
            self._processing.pop(queue, None)
            self._dead_letters.pop(queue, None)
            return True
        return False

    async def get_queue_info(self, queue: str) -> Optional[Dict[str, Any]]:
        if queue not in self._queues and queue not in self._queue_configs:
            return None

        config = self._queue_configs.get(queue, QueueConfig())
        return {
            "name": queue,
            "message_count": len(self._queues[queue]),
            "dead_letter_count": len(self._dead_letters.get(queue, [])),
            "processing_count": len(self._processing[queue]),
            "max_delivery_count": config.max_delivery_count,
            "lock_duration_seconds": config.lock_duration.total_seconds(),
        }

    async def purge_queue(self, queue: str) -> int:
        count = len(self._queues[queue])
        self._queues[queue].clear()
        self._processing[queue].clear()
        return count

    # --- Health Operations ---

    async def is_healthy(self) -> bool:
        return True

    async def get_status(self) -> dict:
        total_messages = sum(len(q) for q in self._queues.values())
        total_dead_letters = sum(len(q) for q in self._dead_letters.values())

        return {
            "type": "in-memory",
            "healthy": True,
            "queues": list(self._queues.keys()),
            "total_messages": total_messages,
            "total_dead_letters": total_dead_letters,
            "topics": list(self._subscriptions.keys()),
        }
