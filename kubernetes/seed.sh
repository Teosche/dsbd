#!/bin/bash
set -e 

USER_API="http://127.0.0.1:30000"
INTEREST_API="http://127.0.0.1:30001"

echo "Creating users..."

curl -s -X POST "$USER_API/users" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: user-mario-rossi" \
  -d '{
    "email": "mario.rossi@gmail.com",
    "first_name": "Mario",
    "last_name": "Rossi",
    "tax_code": "RSSMRA85D15Z404E",
    "iban": "IT19Z1234567890000123456789"
  }'

curl -s -X POST "$USER_API/users" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: user-mario-verdi" \
  -d '{
    "email": "mario.verdi@gmail.com",
    "first_name": "Mario",
    "last_name": "Verdi",
    "tax_code": "VRDMRA85D15Z404A",
    "iban": "IT19Z1234567890000123456781"
  }'


curl -s -X POST "$USER_API/users" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: user-enzo-bianchi" \
  -d '{
    "email": "enzo.bianchi@gmail.com",
    "first_name": "Enzo",
    "last_name": "Bianchi",
    "tax_code": "BNCENZ15Z404E",
    "iban": "IT19Z1234567890000123456789"
  }'

curl -s -X POST "$USER_API/users" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: user-neri-parenti" \
  -d '{
    "email": "neri.parenti@gmail.com",
    "first_name": "Neri",
    "last_name": "Parenti",
    "tax_code": "NRIPRN15Z404E",
    "iban": "IT19Z1234567890000123456789"
  }'

curl -s -X POST "$USER_API/users" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: user-luca-blu" \
  -d '{
    "email": "luca.blu@gmail.com",
    "first_name": "Luca",
    "last_name": "Blu",
    "tax_code": "LUCBLU15Z404E",
    "iban": "IT19Z1234567890000123456789"
  }'


echo ""
echo "Creating interests..."

curl -s -X POST "$INTEREST_API/interests" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mario.rossi@gmail.com",
    "airport_code": "LIRF",
    "high_value": 2,
    "low_value": 1
  }'

curl -s -X POST "$INTEREST_API/interests" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mario.rossi@gmail.com",
    "airport_code": "LICC",
    "high_value": 5,
    "low_value": 2
  }'

curl -s -X POST "$INTEREST_API/interests" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mario.verdi@gmail.com",
    "airport_code": "LICC",
    "high_value": 7,
    "low_value": 3
  }'

curl -s -X POST "$INTEREST_API/interests" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mario.verdi@gmail.com",
    "airport_code": "LIMC",
    "high_value": 10,
    "low_value": 4
  }'

curl -s -X POST "$INTEREST_API/interests" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "enzo.bianchi@gmail.com",
    "airport_code": "KJFK",
    "high_value": 20,
    "low_value": 5
  }'

curl -s -X POST "$INTEREST_API/interests" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "neri.parenti@gmail.com",
    "airport_code": "EGLL",
    "high_value": 15,
    "low_value": 3
  }'

curl -s -X POST "$INTEREST_API/interests" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "luca.blu@gmail.com",
    "airport_code": "RJTT",
    "high_value": 12,
    "low_value": 2
  }'
