"""OpenTelemetry configuration and utilities.

Provides distributed tracing, metrics, and logging integration
with Azure Monitor and OTLP exporters.
"""

import logging
from contextlib import contextmanager
from typing import Optional, Generator, Any

from opentelemetry import trace, metrics
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk.resources import Resource, SERVICE_NAME, SERVICE_VERSION
from opentelemetry.trace import Span, Status, StatusCode
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor

logger = logging.getLogger(__name__)

# Global tracer and meter instances
_tracer: Optional[trace.Tracer] = None
_meter: Optional[metrics.Meter] = None
_initialized: bool = False


def init_telemetry(
    service_name: str,
    service_version: str,
    app_insights_connection_string: Optional[str] = None,
    otlp_endpoint: Optional[str] = None,
    enable_console_export: bool = False,
) -> None:
    """Initialize OpenTelemetry with Azure Monitor and/or OTLP exporters.

    Args:
        service_name: Name of the service for resource identification.
        service_version: Version of the service.
        app_insights_connection_string: Azure Application Insights connection string.
        otlp_endpoint: OTLP collector endpoint (e.g., http://localhost:4317).
        enable_console_export: Enable console exporter for debugging.
    """
    global _tracer, _meter, _initialized

    if _initialized:
        logger.warning("Telemetry already initialized, skipping...")
        return

    # Create resource with service information
    resource = Resource.create({
        SERVICE_NAME: service_name,
        SERVICE_VERSION: service_version,
        "deployment.environment": "production",
    })

    # Initialize TracerProvider
    tracer_provider = TracerProvider(resource=resource)

    # Add Azure Monitor exporter if configured
    if app_insights_connection_string:
        try:
            from azure.monitor.opentelemetry.exporter import AzureMonitorTraceExporter

            azure_exporter = AzureMonitorTraceExporter(
                connection_string=app_insights_connection_string
            )
            tracer_provider.add_span_processor(BatchSpanProcessor(azure_exporter))
            logger.info("Azure Monitor trace exporter configured")
        except ImportError:
            logger.warning("Azure Monitor exporter not available")
        except Exception as e:
            logger.error(f"Failed to configure Azure Monitor exporter: {e}")

    # Add OTLP exporter if configured
    if otlp_endpoint:
        try:
            from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import (
                OTLPSpanExporter,
            )

            otlp_exporter = OTLPSpanExporter(endpoint=otlp_endpoint, insecure=True)
            tracer_provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
            logger.info(f"OTLP trace exporter configured: {otlp_endpoint}")
        except ImportError:
            logger.warning("OTLP exporter not available")
        except Exception as e:
            logger.error(f"Failed to configure OTLP exporter: {e}")

    # Add console exporter for debugging
    if enable_console_export:
        try:
            from opentelemetry.sdk.trace.export import ConsoleSpanExporter

            tracer_provider.add_span_processor(
                BatchSpanProcessor(ConsoleSpanExporter())
            )
            logger.info("Console trace exporter configured")
        except Exception as e:
            logger.error(f"Failed to configure console exporter: {e}")

    # Set the global tracer provider
    trace.set_tracer_provider(tracer_provider)

    # Initialize MeterProvider for metrics
    metric_readers = []

    if app_insights_connection_string:
        try:
            from azure.monitor.opentelemetry.exporter import AzureMonitorMetricExporter

            azure_metric_exporter = AzureMonitorMetricExporter(
                connection_string=app_insights_connection_string
            )
            metric_readers.append(
                PeriodicExportingMetricReader(azure_metric_exporter, export_interval_millis=60000)
            )
            logger.info("Azure Monitor metric exporter configured")
        except Exception as e:
            logger.error(f"Failed to configure Azure Monitor metric exporter: {e}")

    if otlp_endpoint:
        try:
            from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import (
                OTLPMetricExporter,
            )

            otlp_metric_exporter = OTLPMetricExporter(endpoint=otlp_endpoint, insecure=True)
            metric_readers.append(
                PeriodicExportingMetricReader(otlp_metric_exporter, export_interval_millis=60000)
            )
        except Exception as e:
            logger.error(f"Failed to configure OTLP metric exporter: {e}")

    if metric_readers:
        meter_provider = MeterProvider(resource=resource, metric_readers=metric_readers)
        metrics.set_meter_provider(meter_provider)

    # Get tracer and meter instances
    _tracer = trace.get_tracer(service_name, service_version)
    _meter = metrics.get_meter(service_name, service_version)
    _initialized = True

    logger.info(f"OpenTelemetry initialized for {service_name} v{service_version}")


def instrument_fastapi(app: Any) -> None:
    """Instrument FastAPI application for automatic tracing.

    Args:
        app: FastAPI application instance.
    """
    FastAPIInstrumentor.instrument_app(app)
    logger.info("FastAPI instrumentation enabled")


def instrument_sqlalchemy(engine: Any) -> None:
    """Instrument SQLAlchemy engine for automatic tracing.

    Args:
        engine: SQLAlchemy engine instance.
    """
    SQLAlchemyInstrumentor().instrument(engine=engine)
    logger.info("SQLAlchemy instrumentation enabled")


def get_tracer() -> trace.Tracer:
    """Get the global tracer instance.

    Returns:
        OpenTelemetry tracer instance.
    """
    global _tracer
    if _tracer is None:
        _tracer = trace.get_tracer(__name__)
    return _tracer


def get_meter() -> metrics.Meter:
    """Get the global meter instance.

    Returns:
        OpenTelemetry meter instance.
    """
    global _meter
    if _meter is None:
        _meter = metrics.get_meter(__name__)
    return _meter


@contextmanager
def create_span(
    name: str,
    attributes: Optional[dict] = None,
    kind: trace.SpanKind = trace.SpanKind.INTERNAL,
) -> Generator[Span, None, None]:
    """Create a new span for tracing.

    Args:
        name: Name of the span.
        attributes: Optional attributes to add to the span.
        kind: Kind of span (INTERNAL, SERVER, CLIENT, PRODUCER, CONSUMER).

    Yields:
        The created span.

    Example:
        with create_span("process_order", {"order_id": "123"}) as span:
            # do work
            span.set_attribute("items_count", 5)
    """
    tracer = get_tracer()
    with tracer.start_as_current_span(name, kind=kind) as span:
        if attributes:
            for key, value in attributes.items():
                span.set_attribute(key, value)
        yield span


def record_exception(span: Span, exception: Exception, reraise: bool = True) -> None:
    """Record an exception on a span.

    Args:
        span: The span to record the exception on.
        exception: The exception to record.
        reraise: Whether to re-raise the exception after recording.
    """
    span.record_exception(exception)
    span.set_status(Status(StatusCode.ERROR, str(exception)))

    if reraise:
        raise exception


# Pre-defined metrics
def create_request_counter(name: str = "http_requests_total") -> metrics.Counter:
    """Create a counter for HTTP requests."""
    meter = get_meter()
    return meter.create_counter(
        name=name,
        description="Total number of HTTP requests",
        unit="1",
    )


def create_request_duration_histogram(
    name: str = "http_request_duration_seconds",
) -> metrics.Histogram:
    """Create a histogram for HTTP request duration."""
    meter = get_meter()
    return meter.create_histogram(
        name=name,
        description="HTTP request duration in seconds",
        unit="s",
    )


def create_active_requests_gauge(
    name: str = "http_active_requests",
) -> metrics.UpDownCounter:
    """Create a gauge for active HTTP requests."""
    meter = get_meter()
    return meter.create_up_down_counter(
        name=name,
        description="Number of active HTTP requests",
        unit="1",
    )
