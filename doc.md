# Project Documentation

## 1. Introduction

This document provides a detailed overview of the distributed systems project, which consists of a Dockerized microservices-based application. The primary objective of this project is to design and develop a system capable of managing user data and collecting, processing, and serving flight information from the OpenSky Network.

The system is composed of two main microservices:

*   **User Manager**: Responsible for handling user registration, deletion, and providing user information.
*   **Data Collector**: Responsible for fetching flight data from the OpenSky Network based on user interests, storing it, and providing processed data through its own API.

The project emphasizes a clean architecture, separation of concerns, and robust inter-service communication.

## 2. System Architecture

### 2.1. Overview

The architecture is designed following a microservices pattern, where each service has a specific responsibility and can be developed, deployed, and scaled independently. The system uses a combination of RESTful APIs for external client communication and gRPC for efficient, internal inter-service communication. Each microservice has its own dedicated PostgreSQL database, ensuring loose coupling and data isolation.

### 2.2. Architectural Diagram

![Architectural Diagram](architecture.png)

### 2.3. Components

### 3.1. User Manager Microservice

*   **Purpose**: To manage user information, including creation, deletion, and retrieval of user data. It acts as the authority for user identity within the system.
*   **File Structure**:
    *   `app.py`: Main application entry point.
    *   `config.py`: Configuration variables.
    *   `models.py`: SQLAlchemy database models.
    *   `routes.py`: Flask API routes.
    *   `services.py`: Business logic (e.g., gRPC clients).
    *   `grpc_server.py`: gRPC server implementation.

*   **API Endpoints**:
    *   `GET /ping`: A health check endpoint.
    *   `POST /users`: Creates a new user.
        *   **Request Body**: `{"email": "...", "first_name": "...", "last_name": "...", "tax_code": "...", "iban": "..."}`
        *   **Response**: `{"message": "User created successfully"}`
    *   `GET /users`: Retrieves a list of all users.
    *   `GET /users/<email>`: Retrieves a single user by email.
    *   `DELETE /users/<email>`: Deletes a user by email.

*   **gRPC Service**:
    *   **Service**: `UserService`
    *   **Method**: `CheckUserExists(UserRequest) returns (UserResponse)`
        *   **Description**: Checks if a user with the given email exists in the database.

### 3.2. Data Collector Microservice

*   **Purpose**: To collect flight data based on user interests, store it, and provide endpoints for data retrieval and analysis. It runs a background job to periodically fetch data from the OpenSky Network.
*   **File Structure**:
    *   `app.py`: Main application entry point.
    *   `config.py`: Configuration variables.
    *   `models.py`: SQLAlchemy database models.
    *   `routes.py`: Flask API routes.
    *   `services.py`: Business logic (data collection, OpenSky API interaction).
    *   `grpc_server.py`: gRPC server implementation.

*   **API Endpoints**:
    *   `GET /ping`: A health check endpoint.
    *   `POST /interests`: Adds a new airport interest for a user.
        *   **Request Body**: `{"email": "...", "airport_code": "..."}`
        *   **Response**: `{"message": "Interest added and data fetch initiated"}`
    *   `DELETE /interests`: Removes an airport interest for a user.
        *   **Request Body**: `{"email": "...", "airport_code": "..."}`
    *   `GET /interests/<email>`: Retrieves all airport interests for a user.
    *   `GET /flights/<airport_code>`: Retrieves flights for a specific airport. Supports `type` query parameter (`arrivals` or `departures`).
    *   `GET /flights/average/<icao>`: Calculates and returns the average number of flights per day for a given airport.
    *   `GET /flights/last/<icao>`: Returns the most recent flight recorded for a given airport.

*   **gRPC Service**:
    *   **Service**: `DataCollectorService`
    *   **Method**: `DeleteUserInterests(UserRequest) returns (DeleteInterestsResponse)`
        *   **Description**: Deletes all interests associated with a given user's email. This is called by the User Manager when a user is deleted.

## 4. Implementation Choices

*   **Framework**: **Flask** was chosen as the web framework for its lightweight nature, simplicity, and extensive documentation. It provides the necessary tools to build RESTful APIs without imposing a rigid structure, which is well-suited for microservices development.
*   **ORM**: **SQLAlchemy** is used as the Object-Relational Mapper (ORM). It offers a powerful and flexible way to interact with the relational database, abstracting away the SQL queries and allowing developers to work with Python objects. Its declarative base and session management are well-suited for the application's needs.
*   **Inter-service Communication**: **gRPC** was chosen for communication between the User Manager and Data Collector. Its use of Protocol Buffers allows for a clear, contract-first definition of services and messages, ensuring type safety and high performance, which are critical in a distributed environment.
*   **Containerization**: **Docker** and **Docker Compose** are used to containerize the application. This approach provides a consistent and reproducible environment for development, testing, and deployment. It simplifies dependency management and ensures that the application runs the same way on any machine.
*   **Code Structure**: The code within each microservice was **refactored** to follow a clear and organized structure, separating concerns into different files. This improves maintainability, readability, and scalability of the code.

### 4.1 Coding Standards

The Python code in this project adheres to the **PEP 8** style guide to ensure consistency and readability. All docstrings for modules, classes, and functions are written to comply with the **PEP 257** standard, providing clear and comprehensive documentation directly within the code.

## 5. Database Schema

### 5.1. User Manager DB

*   **`users` table**:
    *   `email` (String, Primary Key)
    *   `first_name` (String)
    *   `last_name` (String)
    *   `tax_code` (String, Optional, Unique)
    *   `iban` (String, Optional)

*   **`idempotency_keys` table**:
    *   `key` (String, Primary Key) - The unique idempotency key provided by the client.
    *   `status` (String) - Current status of the request (`in-progress`, `completed`).
    *   `created_at` (DateTime) - Timestamp of when the key was created.
    *   `response_code` (Integer, Optional) - HTTP status code of the cached response.
    *   `response_body` (Text, Optional) - JSON body of the cached response.
    *   `user_email` (String) - Email of the user associated with the request (not a foreign key).

### 5.2. Data Collector DB

*   **`user_interests` table**:
    *   `id` (Integer, Primary Key)
    *   `user_email` (String)
    *   `airport_code` (String)
*   **`flight_data` table**:
    *   `id` (Integer, Primary Key)
    *   `icao24` (String)
    *   `first_seen` (DateTime)
    *   `est_departure_airport` (String, Optional)
    *   `last_seen` (DateTime)
    *   `est_arrival_airport` (String, Optional)
    *   `callsign` (String, Optional)
    *   `est_departure_airport_horiz_distance` (Integer, Optional)
    *   `est_departure_airport_vert_distance` (Integer, Optional)
    *   `est_arrival_airport_horiz_distance` (Integer, Optional)
    *   `est_arrival_airport_vert_distance` (Integer, Optional)
    *   `departure_airport_candidates_count` (Integer, Optional)
    *   `arrival_airport_candidates_count` (Integer, Optional)

## 6. Setup and Execution

### 6.1. Prerequisites

*   Docker
*   Docker Compose (v1 or v2)

### 6.2. Configuration

Before running the application, you need to configure your OpenSky Network API credentials.

Open the `.env` file and replace `your_api_client_id` and `your_api_client_secret` with your actual OpenSky Network credentials.

### 6.3. Running the Application

You can run the entire application using Docker Compose.

**Using Docker Compose v1:**

```bash
docker-compose up --build
```

**Using Docker Compose v2:**

```bash
docker compose up --build
```

The services will be available at the following addresses:
*   **User Manager**: `http://localhost:5001`
*   **Data Collector**: `http://localhost:5002`

## 7. At-Most-Once Semantics (Idempotency)

To ensure robustness and prevent duplicate data processing in case of network failures or client retries, the system implements an "at-most-once" delivery guarantee for all state-changing operations in the `User Manager` service (`POST /users` and `DELETE /users/<email>`).

### 7.1. Implementation Details

The idempotency logic is handled at the application layer using a combination of a request header and a dedicated database table.

1.  **Idempotency-Key Header**: The client must send a unique identifier for each state-changing request in an `Idempotency-Key` HTTP header.

2.  **`idempotency_keys` Table**: A table in the `user_manager_db` is used to store the status and result of each request. The table includes the idempotency key, the status of the request (`in-progress` or `completed`), and the response body and status code that were originally returned.

3.  **Execution Flow**:
    *   When a request with an `Idempotency-Key` arrives, the server first checks the `idempotency_keys` table.
    *   **If the key exists and its status is `completed`**, the server immediately returns the stored response without re-processing the request.
    *   **If the key exists and its status is `in-progress`**, it means a concurrent request with the same key is being processed. The server returns a `409 Conflict` error to prevent a race condition.
    *   **If the key does not exist**, the server creates a new entry in the table with the status `in-progress`, executes the business logic (e.g., creates the user), and then updates the entry with the status `completed` along with the final response body and code.

This mechanism ensures that an operation is performed at most once, even if the client sends the same request multiple times.

### 7.2. How to Test with Postman

Here is a detailed guide on how to test the idempotency implementation.

#### Initial Setup

1.  **`Content-Type` Header**: For `POST` requests, set the `Content-Type` header to `application/json`.
2.  **`Idempotency-Key` Header**: Add an `Idempotency-Key` header to your `POST /users` and `DELETE /users/<email>` requests.

#### Scenario 1: Successful First Request

1.  **Action**:
    *   Create a `POST /users` request to `http://localhost:5001/users`.
    *   In **Headers**, set `Idempotency-Key` to `{{$guid}}`. This Postman variable generates a new GUID for each request.
    *   In the **Body**, provide the user's JSON data.
    *   Send the request.
2.  **Expected Result**: A `201 Created` response. The user and the idempotency key are stored in the database.

#### Scenario 2: Repeated Request (Same Key)

1.  **Action**:
    *   Take the previous request. **Do not change the `Idempotency-Key`**. If you used `{{$guid}}`, copy the value that was actually sent and paste it as a static value or repeat the **scenario 1** forcing a key, for example: `3f9d2e1b-8c4a-4d6f-b1e2-5a7f8c2d9e4a`.
    *   Send the request again.
2.  **Expected Result**: An immediate `201 Created` response. The server returns the cached response, and no new user is created. You will not see a "duplicate key" error from the database in the service logs.

#### Scenario 3: Creating a User That Already Exists (New Key)

1.  **Action**:
    *   Create a `POST /users` request for a user that already exists.
    *   Use a **new** `Idempotency-Key` (e.g., use `{{$guid}}` again).
    *   Send the request.
2.  **Expected Result**: A `409 Conflict` response. The server attempts to create the user, the database reports a conflict, and this "conflict" result is then cached for the new idempotency key.

#### Scenario 4: Request Without Idempotency Key

1.  **Action**:
    *   Disable or remove the `Idempotency-Key` header from the request.
    *   Send it.
2.  **Expected Result**: A `400 Bad Request` with an error message indicating that the header is required.
