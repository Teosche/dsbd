# dsbd_hw1

This project follows the guidelines provided in the supplied .pdf

Students who carried out this project:
- Dario Camonita
- Matteo Jacopo Schembri

It is currently a **Work in Progress (WIP)** and it has been developed using GNU/Linux and MacOS. 
It is not intended to be used in production environments.

It is managed by Python, gRPC and PostgreSQL and it uses `docker-compose` to handle the containers (database, user_manager and data_collector). 
To start this small infrastructure, open a terminal window and run:

```
docker-compose up --build
```

Stop the containers with:

```
docker-compose down
```

Add a new user with:

```
curl -X POST http://localhost:5001/users \
-H "Content-Type: application/json" \
-d '{"email": "mario.rossi@example.com", "nome": "Mario", "cognome": "Rossi"}'
```

Get a user with:

```
curl http://localhost:5001/users/mario.rossi@example.com
```

NOTE: we may need to remove **all** our containers to clean our system. To do so, we just run: `docker system prune -a`

## OpenSky Documentation

https://openskynetwork.github.io/opensky-api/rest.html

```curl -H "Authorization: Bearer $TOKEN" https://opensky-network.org/api/states/all | jq .```

Current API limitations: https://openskynetwork.github.io/opensky-api/rest.html#limitations
