#!/bin/bash
# Script de backup MongoDB

BACKUP_DIR="./backups/mongodb_$(date +%Y%m%d_%H%M%S)"

echo "💾 Backup MongoDB - SEEG-AI"
echo "============================"
echo ""
echo "📁 Dossier de backup: $BACKUP_DIR"
echo ""

# Créer le dossier de backup
mkdir -p "$BACKUP_DIR"

# Faire le backup dans le container
echo "🔄 Création du backup..."
docker exec seeg-mongodb mongodump \
  --username=Sevan \
  --password=SevanSeeg2025 \
  --authenticationDatabase=admin \
  --db=SEEG-AI \
  --out=/tmp/backup

# Copier le backup vers l'hôte
echo "📦 Copie vers l'hôte..."
docker cp seeg-mongodb:/tmp/backup/SEEG-AI "$BACKUP_DIR/"

# Nettoyer dans le container
docker exec seeg-mongodb rm -rf /tmp/backup

# Créer un fichier d'info
echo "Backup créé le $(date)" > "$BACKUP_DIR/info.txt"
echo "Database: SEEG-AI" >> "$BACKUP_DIR/info.txt"
echo "Collection: candidats" >> "$BACKUP_DIR/info.txt"

# Compter les documents
COUNT=$(docker exec seeg-mongodb mongosh \
  -u Sevan -p "SevanSeeg2025" \
  --authenticationDatabase admin \
  SEEG-AI \
  --quiet \
  --eval "db.candidats.countDocuments()")
echo "Documents: $COUNT" >> "$BACKUP_DIR/info.txt"

echo ""
echo "✅ Backup terminé !"
echo "📂 Emplacement: $BACKUP_DIR"
echo "📄 Documents sauvegardés: $COUNT"
echo ""
echo "Pour restaurer:"
echo "  docker cp $BACKUP_DIR/SEEG-AI seeg-mongodb:/tmp/restore"
echo "  docker exec seeg-mongodb mongorestore -u Sevan -p SevanSeeg2025 --authenticationDatabase admin --db SEEG-AI /tmp/restore"

