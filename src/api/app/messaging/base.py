"""Abstract base classes for messaging operations.

These abstractions allow swapping message broker implementations without
changing business logic. Implementations can be:
- Azure Service Bus
- RabbitMQ
- In-memory (for testing/development)
- Redis Pub/Sub
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, Callable, Dict, List, Optional, Awaitable
from uuid import UUID, uuid4
from enum import Enum


class MessageStatus(Enum):
    """Message processing status."""

    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    DEAD_LETTERED = "dead_lettered"


@dataclass
class Message:
    """Message entity for queue/topic operations.

    Attributes:
        id: Unique message identifier
        body: Message payload (typically JSON string)
        content_type: MIME type of the body
        correlation_id: ID for request-response correlation
        properties: Custom message properties
        enqueued_at: When the message was enqueued
        delivery_count: Number of delivery attempts
        scheduled_at: When to deliver (for scheduled messages)
    """

    body: str
    id: UUID = field(default_factory=uuid4)
    content_type: str = "application/json"
    correlation_id: Optional[str] = None
    properties: Dict[str, str] = field(default_factory=dict)
    enqueued_at: datetime = field(default_factory=datetime.utcnow)
    delivery_count: int = 0
    scheduled_at: Optional[datetime] = None
    status: MessageStatus = MessageStatus.PENDING


# Type alias for message handlers
MessageHandler = Callable[[Message], Awaitable[None]]


class BaseMessageBroker(ABC):
    """Abstract base message broker defining queue and topic operations.

    This interface defines the contract for all message broker implementations.
    Business logic depends on this abstraction, not concrete implementations.

    Example:
        ```python
        class ServiceBusBroker(BaseMessageBroker):
            async def send_to_queue(self, queue: str, message: Message):
                await self.client.get_queue_sender(queue).send_messages(...)

        class InMemoryBroker(BaseMessageBroker):
            async def send_to_queue(self, queue: str, message: Message):
                self._queues[queue].append(message)
        ```
    """

    # --- Queue Operations ---

    @abstractmethod
    async def send_to_queue(
        self,
        queue: str,
        message: Message,
        delay: Optional[timedelta] = None,
    ) -> bool:
        """Send a message to a queue.

        Args:
            queue: Queue name
            message: Message to send
            delay: Optional delay before message becomes visible

        Returns:
            True if message was sent successfully
        """
        pass

    @abstractmethod
    async def send_batch_to_queue(
        self,
        queue: str,
        messages: List[Message],
    ) -> int:
        """Send multiple messages to a queue.

        Args:
            queue: Queue name
            messages: List of messages to send

        Returns:
            Number of messages sent successfully
        """
        pass

    @abstractmethod
    async def receive_from_queue(
        self,
        queue: str,
        max_messages: int = 1,
        timeout: Optional[timedelta] = None,
    ) -> List[Message]:
        """Receive messages from a queue.

        Args:
            queue: Queue name
            max_messages: Maximum number of messages to receive
            timeout: How long to wait for messages

        Returns:
            List of received messages
        """
        pass

    @abstractmethod
    async def complete_message(self, queue: str, message: Message) -> bool:
        """Mark a message as successfully processed.

        Args:
            queue: Queue name
            message: Message to complete

        Returns:
            True if message was completed
        """
        pass

    @abstractmethod
    async def abandon_message(self, queue: str, message: Message) -> bool:
        """Release a message back to the queue for redelivery.

        Args:
            queue: Queue name
            message: Message to abandon

        Returns:
            True if message was abandoned
        """
        pass

    @abstractmethod
    async def dead_letter_message(
        self,
        queue: str,
        message: Message,
        reason: str,
    ) -> bool:
        """Move a message to the dead letter queue.

        Args:
            queue: Queue name
            message: Message to dead letter
            reason: Reason for dead lettering

        Returns:
            True if message was dead lettered
        """
        pass

    # --- Topic/Subscription Operations ---

    @abstractmethod
    async def publish_to_topic(
        self,
        topic: str,
        message: Message,
    ) -> bool:
        """Publish a message to a topic.

        Args:
            topic: Topic name
            message: Message to publish

        Returns:
            True if message was published
        """
        pass

    @abstractmethod
    async def subscribe(
        self,
        topic: str,
        subscription: str,
        handler: MessageHandler,
    ) -> None:
        """Subscribe to a topic with a message handler.

        Args:
            topic: Topic name
            subscription: Subscription name
            handler: Async function to handle messages
        """
        pass

    @abstractmethod
    async def unsubscribe(
        self,
        topic: str,
        subscription: str,
    ) -> bool:
        """Unsubscribe from a topic.

        Args:
            topic: Topic name
            subscription: Subscription name

        Returns:
            True if unsubscribed successfully
        """
        pass

    # --- Queue Management ---

    @abstractmethod
    async def create_queue(
        self,
        queue: str,
        max_delivery_count: int = 10,
        lock_duration: timedelta = timedelta(minutes=1),
    ) -> bool:
        """Create a queue (if it doesn't exist).

        Args:
            queue: Queue name
            max_delivery_count: Max retries before dead lettering
            lock_duration: How long a message is locked during processing

        Returns:
            True if queue was created or already exists
        """
        pass

    @abstractmethod
    async def delete_queue(self, queue: str) -> bool:
        """Delete a queue.

        Args:
            queue: Queue name

        Returns:
            True if queue was deleted
        """
        pass

    @abstractmethod
    async def get_queue_info(self, queue: str) -> Optional[Dict[str, Any]]:
        """Get queue information.

        Args:
            queue: Queue name

        Returns:
            Dict with queue info (message count, etc.) or None
        """
        pass

    # --- Utility ---

    @abstractmethod
    async def purge_queue(self, queue: str) -> int:
        """Remove all messages from a queue.

        Args:
            queue: Queue name

        Returns:
            Number of messages purged
        """
        pass


class MessageBrokerHealth(ABC):
    """Abstract interface for message broker health checking."""

    @abstractmethod
    async def is_healthy(self) -> bool:
        """Check if broker is healthy and accepting connections.

        Returns:
            True if healthy, False otherwise
        """
        pass

    @abstractmethod
    async def get_status(self) -> dict:
        """Get detailed broker status.

        Returns:
            Dict with status information (queues, connections, etc.)
        """
        pass
