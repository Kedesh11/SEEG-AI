# Script de backup MongoDB (Windows)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = ".\backups\mongodb_$timestamp"

Write-Host "💾 Backup MongoDB - SEEG-AI" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 Dossier de backup: $backupDir" -ForegroundColor Yellow
Write-Host ""

# Créer le dossier de backup
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

# Faire le backup dans le container
Write-Host "🔄 Création du backup..." -ForegroundColor Yellow
docker exec seeg-mongodb mongodump `
  --username=Sevan `
  --password="SevanSeeg2025" `
  --authenticationDatabase=admin `
  --db=SEEG-AI `
  --out=/tmp/backup

# Copier le backup vers l'hôte
Write-Host "📦 Copie vers l'hôte..." -ForegroundColor Yellow
docker cp seeg-mongodb:/tmp/backup/SEEG-AI "$backupDir\"

# Nettoyer dans le container
docker exec seeg-mongodb rm -rf /tmp/backup

# Créer un fichier d'info
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$count = docker exec seeg-mongodb mongosh `
  -u Sevan -p "SevanSeeg2025" `
  --authenticationDatabase admin `
  SEEG-AI `
  --quiet `
  --eval "db.candidats.countDocuments()"

@"
Backup créé le $date
Database: SEEG-AI
Collection: candidats
Documents: $count
"@ | Out-File -FilePath "$backupDir\info.txt" -Encoding UTF8

Write-Host ""
Write-Host "✅ Backup terminé !" -ForegroundColor Green
Write-Host "📂 Emplacement: $backupDir" -ForegroundColor Cyan
Write-Host "📄 Documents sauvegardés: $count" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pour restaurer:" -ForegroundColor Yellow
Write-Host "  docker cp $backupDir\SEEG-AI seeg-mongodb:/tmp/restore"
Write-Host "  docker exec seeg-mongodb mongorestore -u Sevan -p 'Sevan@Seeg' --authenticationDatabase admin --db SEEG-AI /tmp/restore"

