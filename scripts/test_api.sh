#!/bin/bash

# Script de test de l'API SEEG-AI

API_URL="${1:-http://localhost:8000}"

echo "🧪 Tests de l'API SEEG-AI"
echo "API URL: $API_URL"
echo "=========================================="
echo ""

# Test 1: Health check
echo "1️⃣  Test Health Check"
echo "GET $API_URL/health"
curl -s "$API_URL/health" | jq '.' || echo "❌ Échec"
echo ""
echo "=========================================="
echo ""

# Test 2: Root endpoint
echo "2️⃣  Test Root Endpoint"
echo "GET $API_URL/"
curl -s "$API_URL/" | jq '.' || echo "❌ Échec"
echo ""
echo "=========================================="
echo ""

# Test 3: Get all candidatures
echo "3️⃣  Test Get All Candidatures"
echo "GET $API_URL/candidatures"
response=$(curl -s "$API_URL/candidatures")
count=$(echo "$response" | jq '. | length')
echo "Nombre de candidatures: $count"
echo "$response" | jq '.' || echo "❌ Échec"
echo ""
echo "=========================================="
echo ""

# Test 4: Search by first name
echo "4️⃣  Test Search by First Name"
echo "GET $API_URL/candidatures/search?first_name=Sevan"
curl -s "$API_URL/candidatures/search?first_name=Sevan" | jq '.' || echo "❌ Échec"
echo ""
echo "=========================================="
echo ""

# Test 5: Search by last name
echo "5️⃣  Test Search by Last Name"
echo "GET $API_URL/candidatures/search?last_name=Kedesh"
curl -s "$API_URL/candidatures/search?last_name=Kedesh" | jq '.' || echo "❌ Échec"
echo ""
echo "=========================================="
echo ""

# Test 6: Search without parameters (should fail)
echo "6️⃣  Test Search Without Parameters (devrait échouer)"
echo "GET $API_URL/candidatures/search"
curl -s "$API_URL/candidatures/search" | jq '.' || echo "❌ Échec (attendu)"
echo ""
echo "=========================================="
echo ""

echo "✅ Tests terminés"

