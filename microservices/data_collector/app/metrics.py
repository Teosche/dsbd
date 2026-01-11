"""
Prometheus configuration for the Data Collector microservice.
"""

import os
import time
from functools import wraps
from flask import request
from prometheus_client import Counter, Gauge, generate_latest, CONTENT_TYPE_LATEST

NODE_NAME = os.environ.get("NODE_NAME", os.environ.get("HOSTNAME", "unknown"))
SERVICE_NAME = "data_collector"

# COUNTER: Total number of HTTP requests received
http_requests_total = Counter(
    "http_requests_total",
    "Total number of HTTP requests received",
    ["service", "node", "method", "endpoint", "status"]
)

# GAUGE: Response time of the last request (in seconds)
http_request_duration_seconds = Gauge(
    "http_request_duration_seconds",
    "HTTP request duration (in seconds)",
    ["service", "node", "method", "endpoint"]
)

# GAUGE: Time taken to fetch data from OpenSky API
opensky_api_duration_seconds = Gauge(
    "opensky_api_duration_seconds",
    "Time taken to fetch data from OpenSky API in seconds",
    ["service", "node", "airport_code"]
)

# COUNTER: Number of OpenSky API calls
opensky_api_calls_total = Counter(
    "opensky_api_calls_total",
    "Total number of OpenSky API calls",
    ["service", "node", "status"]
)

# GAUGE: Number of flights fetched in the last collection
flights_fetched_last_collection = Gauge(
    "flights_fetched_last_collection",
    "Number of flights fetched in the last data collection",
    ["service", "node", "airport_code"]
)

# GAUGE: Number of active requests
http_requests_in_progress = Gauge(
    "http_requests_in_progress",
    "Number of HTTP requests currently being processed",
    ["service", "node"]
)


def track_requests(func):
    """
    A decorator to track HTTP request metrics. The point is to check the request counter
    (incrementing) and record the response time.
    """
    @wraps(func)
    def wrapper(*args, **kwargs):
        http_requests_in_progress.labels(
            service=SERVICE_NAME,
            node=NODE_NAME
        ).inc()

        start_time = time.time()
        status_code = 500

        try:
            response = func(*args, **kwargs)
            if isinstance(response, tuple):
                status_code = response[1]
            else:
                status_code = response.status_code if hasattr(response, 'status_code') else 200
            return response
        except Exception as e:
            status_code = 500
            raise
        finally:
            duration = time.time() - start_time
            endpoint = request.endpoint or request.path

            http_requests_total.labels(
                service=SERVICE_NAME,
                node=NODE_NAME,
                method=request.method,
                endpoint=endpoint,
                status=str(status_code)
            ).inc()

            http_request_duration_seconds.labels(
                service=SERVICE_NAME,
                node=NODE_NAME,
                method=request.method,
                endpoint=endpoint
            ).set(duration)

            http_requests_in_progress.labels(
                service=SERVICE_NAME,
                node=NODE_NAME
            ).dec()

    return wrapper


def track_opensky_call(airport_code: str, duration: float, success: bool):
    """
    Track OpenSky API call metrics.

    airport_code: the airport code being queried
    duration: time taken for the API call in seconds
    success: whether the call was successful
    """
    opensky_api_duration_seconds.labels(
        service=SERVICE_NAME,
        node=NODE_NAME,
        airport_code=airport_code
    ).set(duration)

    opensky_api_calls_total.labels(
        service=SERVICE_NAME,
        node=NODE_NAME,
        status="success" if success else "failure"
    ).inc()


def track_flights_fetched(airport_code: str, count: int):
    """
    Track the number of flights fetched.
    """
    flights_fetched_last_collection.labels(
        service=SERVICE_NAME,
        node=NODE_NAME,
        airport_code=airport_code
    ).set(count)


def metrics_endpoint():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}