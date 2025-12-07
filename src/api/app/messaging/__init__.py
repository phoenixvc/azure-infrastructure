"""Messaging module with abstract interfaces and implementations."""

from .base import (
    BaseMessageBroker,
    Message,
    MessageHandler,
    MessageBrokerHealth,
)
from .memory import InMemoryMessageBroker

__all__ = [
    # Abstract interfaces
    "BaseMessageBroker",
    "Message",
    "MessageHandler",
    "MessageBrokerHealth",
    # Implementations
    "InMemoryMessageBroker",
]
