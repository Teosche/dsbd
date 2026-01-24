# Flight Tracker Kubernetes Deployment Guide

This directory contains the necessary Kubernetes manifests and a helper script to deploy the Flight Tracker microservices architecture locally using [kind](https://kind.sigs.k8s.io/).

## 1. Prerequisites

Ensure you have the following installed:
- **Docker**: Container runtime.
- **kind**: Tool for running local Kubernetes clusters.
- **kubectl**: Kubernetes command-line tool.

## 2. Deployment Script (`deploy.sh`)

The `deploy.sh` script automates the entire lifecycle of the deployment.

### Usage

```bash
Usage: ./kubernetes/deploy.sh [ACTION] [OPTIONS]

Actions:
  up (default)    Create cluster, build images, and deploy.
  down            Delete the kind cluster.
  stop-pf         Stop all active port-forwarding processes.

Options for 'up':
  --pf, --port-forward    Automatically start port-forwarding (5000-5003).
  --ingress               Install NGINX Ingress Controller.
```

## 3. Accessing Services

The services are accessible via multiple methods depending on your needs.

### Method A: NodePorts (Always Available)

The cluster is configured to map these ports directly to your localhost. This is the standard access method.

| Service | Local URL |
| :--- | :--- |
| **User Manager** | `http://localhost:30000` |
| **Data Collector** | `http://localhost:30001` |
| **Alert System** | `http://localhost:30002` |
| **Alert Notifier** | `http://localhost:30003` |
| **Prometheus** | `http://localhost:30090` |

### Method B: Port-Forwarding (using `--pf`)

If you run `./kubernetes/deploy.sh --pf`, the script creates these additional mappings:

| Service | Local URL |
| :--- | :--- |
| **User Manager** | `http://localhost:5000` |
| **Data Collector** | `http://localhost:5001` |
| **Alert System** | `http://localhost:5002` |
| **Alert Notifier** | `http://localhost:5003` |

### Method C: Ingress (using `--ingress`)

If installed, services are routed via port 80/443:

| Service | Ingress URL |
| :--- | :--- |
| **User Manager** | `http://localhost/user-manager` |
| **Data Collector** | `http://localhost/data-collector` |

---

## 4. API Documentation & Examples

These examples use the **NodePorts (Method A)**.

### User Manager (Port 30000)

| Action | Command Example |
|:---|:---|
| **Add User** | `curl -X POST http://localhost:30000/users -H "Content-Type: application/json" -H "Idempotency-Key: key1" -d '{"email": "mario@test.com", "first_name": "Mario", "last_name": "Rossi"}'` |
| **Ping** | `curl http://localhost:30000/ping` |

### Data Collector (Port 30001)

| Action | Command Example |
|:---|:---|
| **Add Interest** | `curl -X POST http://localhost:30001/interests -H "Content-Type: application/json" -d '{"email": "mario@test.com", "airport_code": "LIRF"}'` |
| **Get Flights** | `curl http://localhost:30001/flights/LIRF` |
| **Ping** | `curl http://localhost:30001/ping` |

### Internal Systems (30002 & 30003)

| Service | Ping Command |
|:---|:---|
| **Alert System** | `curl http://localhost:30002/ping` |
| **Alert Notifier** | `curl http://localhost:30003/ping` |

---

## 5. Monitoring (Prometheus)

Access the UI at: [http://localhost:30090](http://localhost:30090)

**Useful Queries:**
- `rate(http_requests_total{service="user-manager"}[1m])`
- `opensky_api_call_duration_seconds`
- `flights_fetched_total`

---

## 6. Configuration & Credentials

### API Keys
The system requires valid credentials for external services. You have two options:
1.  **Create your own**: 
    *   **Telegram**: Use [BotFather](https://t.me/botfather) to create a bot and get a token.
    *   **OpenSky**: Register for a free account at [OpenSky Network](https://opensky-network.org/).
2.  **Request from authors**: You can contact the authors (Dario or Matteo) to receive testing credentials.

Update the `opensky-secrets` and `telegram-secrets` sections in `kubernetes/secrets.yaml` with your keys.

### Infrastructure
The deployment includes:
- **PostgreSQL**: Two instances (User DB, Data DB).
- **Kafka & Zookeeper**: For asynchronous messaging.
- **Prometheus**: For metrics collection.

---

## 7. End-to-End Test: Triggering an Alert

To verify that the entire pipeline is working (from User Manager to Telegram Notification), follow this procedure.

**Note:** The `deploy.sh` script automatically runs `seed.sh`, which populates the database with standard users (e.g., `mario.rossi@gmail.com`) and sample interests.

### Step 1: Get your Telegram Chat ID
1.  Open Telegram and find a bot that reveals your Chat ID (e.g., `@userinfobot`).
2.  Send a message (e.g., `/start`) and note down your numeric ID.

### Step 2: Associate Chat ID with a Seed User
Choose one of the existing users, for example `mario.rossi@gmail.com`, and update their profile with your Chat ID.

```bash
curl -X POST http://localhost:30000/users/telegram \
  -H "Content-Type: application/json" \
  -d 
  {
    "email": "mario.rossi@gmail.com",
    "telegram_chat_id": "YOUR_CHAT_ID"
  }
```

### Step 3: Verify or Add Interests
Check existing interests for the user:
```bash
curl http://localhost:30001/interests/mario.rossi@gmail.com
```

You can add a new interest with low thresholds to ensure an alert is triggered immediately:
```bash
curl -X POST http://localhost:30001/interests \
  -H "Content-Type: application/json" \
  -d 
  {
    "email": "mario.rossi@gmail.com",
    "airport_code": "LIRF",
    "high_value": 0,
    "low_value": -1
  }
```

### Step 4: Add the Bot
Open Telegram and add the project bot: **@sky_dsbd_bot**.

### Step 5: Wait for Notification
The system checks for flights every 5 minutes. If the flight count exceeds the `high_value` (or is below `low_value`), the Alert System will trigger a notification, and you will receive a message from **@sky_dsbd_bot** with the alert details.

---

## 8. Advanced Troubleshooting

### 1. Kafka or Database Connectivity
If logs show `Could not connect to Kafka` or DB errors:
*   **Cause**: Infrastructure services might take longer to start than the microservices.
*   **Solution**: Force a restart of the application pods:
    ```bash
    kubectl rollout restart deployment/user-manager deployment/data-collector deployment/alert-system deployment/alert-notifier-system
    ```

### 2. Prometheus Metrics Missing
If targets are shown as **DOWN** in the Prometheus UI:
*   **Verification**: Ensure the service is healthy by calling the NodePort endpoint directly: `curl http://localhost:30000/metrics`.
*   **Check**: Verify that the pod annotations for scraping are present in the deployment manifests.

### 3. Port Conflicts
If `deploy.sh` fails during cluster creation:
*   **Cause**: Local ports 80, 443, or 30000-30003 are already in use by other processes.
*   **Solution**: Stop conflicting services or run `./kubernetes/deploy.sh down` to clean up old cluster remnants.

### 4. Telegram Notifications Not Received
*   **Bot Interaction**: You must start a conversation with **@sky_dsbd_bot** (send `/start`) before the bot can send you messages.
*   **Secrets**: Double-check that the token in `secrets.yaml` is correct and has no trailing spaces.
*   **Logs**: Check the notifier logs: `kubectl logs -l app=alert-notifier-system`.

### 5. Mock Data Fallback
If flight data seems repetitive or "simulated":
*   **Reason**: The system automatically switches to **Mock Data** if the OpenSky API is unreachable or rate-limited.
*   **Verification**: Check the `data-collector` logs for `Falling back to mock data`.

---

## 9. Cleanup
To completely remove the environment:
```bash
./kubernetes/deploy.sh down
```