# Script de test complet des routes API SEEG-AI

Write-Host "🧪 Test des Routes API SEEG-AI" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$API_URL = "http://localhost:8000"

# Test 1: Root endpoint
Write-Host "1️⃣  Test GET /" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$API_URL/" -Method Get
    Write-Host "✓ Route racine OK" -ForegroundColor Green
    Write-Host "  Message: $($response.message)" -ForegroundColor Gray
    Write-Host "  Version: $($response.version)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Erreur: $_" -ForegroundColor Red
}
Write-Host ""

# Test 2: Health check
Write-Host "2️⃣  Test GET /health" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$API_URL/health" -Method Get
    Write-Host "✓ Health check OK" -ForegroundColor Green
    Write-Host "  Status: $($response.status)" -ForegroundColor Gray
    Write-Host "  Database: $($response.database)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Erreur: $_" -ForegroundColor Red
}
Write-Host ""

# Test 3: Get all candidatures
Write-Host "3️⃣  Test GET /candidatures" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$API_URL/candidatures" -Method Get
    $count = $response.Count
    Write-Host "✓ Route candidatures OK" -ForegroundColor Green
    Write-Host "  Nombre de candidatures: $count" -ForegroundColor Gray
    
    if ($count -gt 0) {
        $first = $response[0]
        Write-Host "  Premier candidat: $($first.first_name) $($first.last_name)" -ForegroundColor Gray
        if ($first.documents.cv) {
            $cvLength = $first.documents.cv.Length
            Write-Host "  Texte CV extrait: $cvLength caractères" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "❌ Erreur: $_" -ForegroundColor Red
}
Write-Host ""

# Test 4: Search by first_name
Write-Host "4️⃣  Test GET /candidatures/search?first_name=Eric" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$API_URL/candidatures/search?first_name=Eric" -Method Get
    $count = $response.Count
    Write-Host "✓ Recherche par prénom OK" -ForegroundColor Green
    Write-Host "  Résultats trouvés: $count" -ForegroundColor Gray
    
    if ($count -gt 0) {
        foreach ($candidat in $response | Select-Object -First 3) {
            Write-Host "  - $($candidat.first_name) $($candidat.last_name)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "❌ Erreur: $_" -ForegroundColor Red
}
Write-Host ""

# Test 5: Search by last_name
Write-Host "5️⃣  Test GET /candidatures/search?last_name=EYOGO" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$API_URL/candidatures/search?last_name=EYOGO" -Method Get
    $count = $response.Count
    Write-Host "✓ Recherche par nom OK" -ForegroundColor Green
    Write-Host "  Résultats trouvés: $count" -ForegroundColor Gray
} catch {
    Write-Host "❌ Erreur: $_" -ForegroundColor Red
}
Write-Host ""

# Test 6: Search without parameters (devrait échouer)
Write-Host "6️⃣  Test GET /candidatures/search (sans paramètres - doit échouer)" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$API_URL/candidatures/search" -Method Get
    Write-Host "❌ Devrait échouer mais a réussi" -ForegroundColor Red
} catch {
    Write-Host "✓ Erreur attendue (400 Bad Request)" -ForegroundColor Green
}
Write-Host ""

Write-Host "================================" -ForegroundColor Cyan
Write-Host "✅ Tests terminés !" -ForegroundColor Green
Write-Host ""

