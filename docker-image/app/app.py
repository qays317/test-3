from flask import Flask, request, jsonify
import time
import os

app = Flask(__name__)

# simulate startup delay (for readiness)
STARTUP_TIME = int(os.getenv("STARTUP_TIME", "5"))
START_TIME = time.time()

REQUEST_COUNT = 0


@app.route("/")
def home():
    global REQUEST_COUNT
    REQUEST_COUNT += 1
    return "Hello from Kubernetes\n", 200


# Liveness probe
@app.route("/health")
def health():
    return "OK", 200


# Readiness probe
@app.route("/ready")
def ready():
    uptime = time.time() - START_TIME
    if uptime < STARTUP_TIME:
        return "NOT READY", 503
    return "READY", 200


# Simulate work / load
@app.route("/work")
def work():
    global REQUEST_COUNT
    REQUEST_COUNT += 1

    delay = request.args.get("delay", default=0, type=float)
    cpu = request.args.get("cpu", default="low")

    if cpu == "high":
        # burn CPU for ~1 second
        end = time.time() + 1
        while time.time() < end:
            pass

    if delay > 0:
        time.sleep(delay)

    return jsonify({
        "status": "work done",
        "delay": delay,
        "cpu": cpu
    }), 200


# Prometheus-style metrics (very simple)
@app.route("/metrics")
def metrics():
    uptime = time.time() - START_TIME
    metrics_text = f"""
# HELP app_uptime_seconds Application uptime
# TYPE app_uptime_seconds gauge
app_uptime_seconds {uptime}

# HELP app_requests_total Total HTTP requests
# TYPE app_requests_total counter
app_requests_total {REQUEST_COUNT}
"""
    return metrics_text, 200, {"Content-Type": "text/plain; version=0.0.4"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

