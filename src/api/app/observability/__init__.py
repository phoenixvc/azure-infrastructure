"""Observability module providing OpenTelemetry integration."""

from .telemetry import (
    init_telemetry,
    get_tracer,
    get_meter,
    create_span,
    record_exception,
)

__all__ = [
    "init_telemetry",
    "get_tracer",
    "get_meter",
    "create_span",
    "record_exception",
]
