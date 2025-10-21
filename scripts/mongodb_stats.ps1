# Script pour afficher les statistiques MongoDB (Windows)

Write-Host "📊 Statistiques MongoDB - SEEG-AI" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📦 Bases de données:" -ForegroundColor Yellow
docker exec seeg-mongodb mongosh `
    -u Sevan -p "SevanSeeg2025" `
    --authenticationDatabase admin `
    --quiet `
    --eval "db.adminCommand('listDatabases').databases.forEach(function(db){print('  - ' + db.name + ' (' + (db.sizeOnDisk/1024/1024).toFixed(2) + ' MB)')})"

Write-Host ""
Write-Host "📁 Collections dans SEEG-AI:" -ForegroundColor Yellow
docker exec seeg-mongodb mongosh `
    -u Sevan -p "SevanSeeg2025" `
    --authenticationDatabase admin `
    SEEG-AI `
    --quiet `
    --eval "db.getCollectionNames().forEach(function(col){print('  - ' + col)})"

Write-Host ""
Write-Host "📄 Nombre de candidatures:" -ForegroundColor Yellow
$count = docker exec seeg-mongodb mongosh `
    -u Sevan -p "SevanSeeg2025" `
    --authenticationDatabase admin `
    SEEG-AI `
    --quiet `
    --eval "db.candidats.countDocuments()"
Write-Host "  Total: $count documents" -ForegroundColor Green

Write-Host ""
Write-Host "🔍 Index:" -ForegroundColor Yellow
docker exec seeg-mongodb mongosh `
    -u Sevan -p "SevanSeeg2025" `
    --authenticationDatabase admin `
    SEEG-AI `
    --quiet `
    --eval "db.candidats.getIndexes().forEach(function(idx){print('  - ' + idx.name + ': ' + JSON.stringify(idx.key))})"

Write-Host ""
Write-Host "💾 Taille de la base:" -ForegroundColor Yellow
docker exec seeg-mongodb mongosh `
    -u Sevan -p "SevanSeeg2025" `
    --authenticationDatabase admin `
    SEEG-AI `
    --quiet `
    --eval "var stats = db.stats(); print('  Storage: ' + (stats.dataSize/1024/1024).toFixed(2) + ' MB')"

Write-Host ""
Write-Host "✅ Statistiques affichées" -ForegroundColor Green

