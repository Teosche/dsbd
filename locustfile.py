import uuid
import random
from locust import HttpUser, task, between

# Configurazione dati di test
AIRPORTS = ["LICC", "LIRF", "LIMC", "KJFK", "EGLL", "RJTT"]
SEED_USER = "mario.rossi@gmail.com"


class FlightTrackerLoadTester(HttpUser):
    wait_time = between(1, 5)

    def on_start(self):
        """Eseguito all'avvio di ogni utente virtuale."""
        self.user_email = f"test_{uuid.uuid4().hex[:8]}@example.com"
        self.idempotency_key = str(uuid.uuid4())

    @task(1)
    def health_check_all(self):
        """Verifica lo stato di salute di tutti i servizi (Low Weight)."""
        services = [30000, 30001, 30002, 30003]
        for port in services:
            with self.client.get(
                f"http://localhost:{port}/ping",
                name=f"Ping Port {port}",
                catch_response=True,
            ) as response:
                if response.status_code != 200:
                    response.failure(f"Service on port {port} is down")

    @task(5)
    def user_manager_lifecycle(self):
        """Simula la creazione e la gestione di un utente (Port 30000)."""
        # 1. Creazione Utente (Idempotente)
        payload = {
            "email": self.user_email,
            "first_name": "Locust",
            "last_name": "User",
        }
        headers = {"Idempotency-Key": self.idempotency_key}

        self.client.post(
            "http://localhost:30000/users",
            json=payload,
            headers=headers,
            name="UM: Create User",
        )

        # 2. Lettura dati utente
        self.client.get(
            f"http://localhost:30000/users/{self.user_email}",
            name="UM: Get User Profile",
        )

        # 3. Aggiornamento Telegram (Simulato)
        self.client.post(
            "http://localhost:30000/users/telegram",
            json={
                "email": self.user_email,
                "telegram_chat_id": str(random.randint(100000, 999999)),
            },
            name="UM: Update Telegram ID",
        )

    @task(10)
    def data_collector_read_ops(self):
        """Simula la consultazione dei voli e interessi (Port 30001 - Heavy Read)."""
        airport = random.choice(AIRPORTS)

        # 1. Visualizza voli per un aeroporto
        self.client.get(
            f"http://localhost:30001/flights/{airport}", name="DC: Get Flights"
        )

        # 2. Visualizza voli con filtro (Arrivi/Partenze)
        self.client.get(
            f"http://localhost:30001/flights/{airport}?type=arrivals",
            name="DC: Get Arrivals",
        )

        # 3. Controlla medie e statistiche
        self.client.get(
            f"http://localhost:30001/flights/average/{airport}", name="DC: Get Average"
        )
        self.client.get(
            f"http://localhost:30001/flights/last/{airport}", name="DC: Get Last Flight"
        )

    @task(3)
    def trigger_alert_logic(self):
        """Simula l'aggiunta di interessi per triggerare la logica Kafka/Alert (Port 30001)."""
        airport = random.choice(AIRPORTS)
        payload = {
            "email": SEED_USER,  # Usiamo un utente esistente dal seed
            "airport_code": airport,
            "high_value": random.randint(10, 50),
            "low_value": random.randint(0, 5),
        }
        self.client.post(
            "http://localhost:30001/interests",
            json=payload,
            name="DC: Add/Update Interest",
        )

    @task(2)
    def test_idempotency_collision(self):
        """Invia deliberatamente la stessa chiave per testare la cache di idempotenza."""
        payload = {
            "email": "duplicate@test.com",
            "first_name": "Dup",
            "last_name": "User",
        }
        headers = {"Idempotency-Key": "fixed-test-key-123"}

        # La prima volta può essere 201 o 409 (se già creato),
        # la seconda deve restituire lo stesso risultato senza errori di DB.
        self.client.post(
            "http://localhost:30000/users",
            json=payload,
            headers=headers,
            name="UM: Idempotency Test",
        )
