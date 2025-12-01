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
