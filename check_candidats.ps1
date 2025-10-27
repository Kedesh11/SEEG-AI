# Script PowerShell pour vérifier rapidement le nombre de candidats
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VERIFICATION CANDIDATS COSMOS DB" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Récupérer la connection string
Write-Host "Récupération de la connection string Cosmos DB..." -ForegroundColor Yellow
$cosmosConnStr = az cosmosdb keys list --name seeg-ai --resource-group seeg-rg --type connection-strings --query "connectionStrings[0].connectionString" --output tsv

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors de la récupération de la connection string" -ForegroundColor Red
    exit 1
}

Write-Host "Connection string récupérée" -ForegroundColor Green

# Lancer le script Python
Write-Host "`nLancement de la vérification..." -ForegroundColor Yellow
python check_candidats_count.py "$cosmosConnStr"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nVérification terminée avec succès" -ForegroundColor Green
}
else {
    Write-Host "`nErreur lors de la vérification" -ForegroundColor Red
}