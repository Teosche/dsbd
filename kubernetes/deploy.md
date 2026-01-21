# Flight Tracker Deployment Guide

## 1. Accessing Services

Since the services run inside a Kubernetes cluster (Kind), you can access them using `kubectl port-forward`.

### API Access
Run these commands in separate terminal windows:
- **User Manager**: `kubectl port-forward svc/user-manager 5000:5000`
- **Data Collector**: `kubectl port-forward svc/data-collector 5001:5000`
- **Alert System**: `kubectl port-forward svc/alert-system 5002:5000`
- **Alert Notifier**: `kubectl port-forward svc/alert-notifier-system 5003:5000`

### Monitoring Access
- **Prometheus UI**: [http://localhost:30090](http://localhost:30090)
- **Metrics (via NodePort or Port-Forward)**:
  - **User Manager**: [http://localhost:30000/metrics](http://localhost:30000/metrics) (NodePort) or [http://localhost:5000/metrics](http://localhost:5000/metrics)
  - **Data Collector**: [http://localhost:5001/metrics](http://localhost:5001/metrics)
  - **Alert System**: [http://localhost:5002/metrics](http://localhost:5002/metrics)
  - **Alert Notifier**: [http://localhost:5003/metrics](http://localhost:5003/metrics)

---

## 2. API Documentation & Examples

Use these examples to test the cluster once port-forwarding is active.

### User Manager (Local Port 5000)

| Action              | Command Example                                                                                                                                                                                                                                                       |
|:--------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Add User**        | `curl -X POST http://localhost:5000/users -H "Content-Type: application/json" -H "Idempotency-Key: key1" -d '{"email": "mario.rossi@gmail.com", "first_name": "Mario", "last_name": "Rossi", "tax_code": "RSSMRA85D15Z404E", "iban": "IT19Z1234567890000123456789"}'` |
| **Add Telegram ID** | `curl -X POST http://localhost:5000/users/telegram -H "Content-Type: application/json" -d '{"email": "mario.rossi@gmail.com", "telegram_chat_id": "your-chat-id"}'`                                                                                                   |
| **Get User**        | `curl http://localhost:5000/users/mario.rossi@gmail.com`                                                                                                                                                                                                              |
| **Delete User**     | `curl -X DELETE http://localhost:5000/users/mario.rossi@gmail.com -H "Idempotency-Key: key2"`                                                                                                                                                                         |
| **Ping**            | `curl http://localhost:5000/ping`                                                                                                                                                                                                                                     |

### Data Collector (Local Port 5001)

| Action             | Command Example                                                                                                                                                                     |
|:-------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Add Interest**   | `curl -X POST http://localhost:5001/interests -H "Content-Type: application/json" -d '{"email": "mario.rossi@gmail.com", "airport_code": "LIRF", "high_value": 2, "low_value": 1}'` |
| **Get Flights**    | `curl http://localhost:5001/flights/LIRF`                                                                                                                                           |
| **Get Departures** | `curl http://localhost:5001/flights/LIRF?type=departures`                                                                                                                           |
| **Get Arrivals**   | `curl http://localhost:5001/flights/LIRF?type=arrivals`                                                                                                                             |
| **Get Interests**  | `curl http://localhost:5001/interests/mario.rossi@gmail.com`                                                                                                                        |
| **Daily Average**  | `curl http://localhost:5001/flights/average/LICC`                                                                                                                                   |
| **Last Flight**    | `curl http://localhost:5001/flights/last/LICC`                                                                                                                                      |
| **Ping**           | `curl http://localhost:5001/ping`                                                                                                                                                   |

### Alert & Notifier Systems (Internal)

These systems primarily process background data but can be reached for health checks:

| Service            | Ping Command                      | Metrics Command                      |
|:-------------------|:----------------------------------|:-------------------------------------|
| **Alert System**   | `curl http://localhost:5002/ping` | `curl http://localhost:5002/metrics` |
| **Alert Notifier** | `curl http://localhost:5003/ping` | `curl http://localhost:5003/metrics` |

---

## 3. Monitoring with Prometheus

### Service Health
1. Open [http://localhost:30090](http://localhost:30090).
2. Go to **Status** → **Targets**.
3. All endpoints (`user-manager`, `data-collector`, `alert-system`, `alert-notifier-system`) should show as **UP**.

### Useful Prometheus Queries
Paste these into the **Graph** tab:
- **Request Traffic**: `rate(http_requests_total{service="user-manager"}[1m])`
- **External API Latency**: `opensky_api_call_duration_seconds`
- **Data Collection Volume**: `flights_fetched_total`
- **Kafka Alert Processing**: `rate(messages_processed_total[5m])`
- **Telegram Success Rate**: `sum(notifications_sent_total{status="success"}) / sum(notifications_sent_total)`

---

## 4. End-to-End test: triggering an alert

To verify that everything is working (Kafka + Alert System + Notifier + Prometheus):

1. **Setup user & interest**:
   ```bash
   # Add a user with your Telegram ID
   curl -X POST http://localhost:5000/users/telegram -H "Content-Type: application/json" -d '{"email": "test@test.com", "telegram_chat_id": "12345678"}'
   
   # Add an interest with low thresholds to trigger an alert immediately
   curl -X POST http://localhost:5001/interests -H "Content-Type: application/json" -d '{"email": "test@test.com", "airport_code": "LIRP", "high_value": 0, "low_value": -1}'
   ```
2. **Observe the flow**:
   * **Alert System**: Should detect that `flight_count > 0` (high_value) and send a notification to Kafka.
   * **Alert Notifier**: Should receive the notification and attempt to send a Telegram message.
3. **Check Prometheus**:
   * Query `messages_processed_total` and `notifications_sent_total`.

---

## 4. Troubleshooting & Cleanup

### View Logs
```bash
# Alert Notifier logs
kubectl logs -l app=alert-notifier-system --tail=50

# Kafka logs
kubectl logs -l app=kafka --tail=50
```

### Delete Cluster
To completely remove the environment:
```bash
kind delete cluster --name flight-tracker
```
