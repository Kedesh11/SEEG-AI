#!/bin/bash
# Script pour nettoyer la base MongoDB

echo "⚠️  Nettoyage MongoDB - SEEG-AI"
echo "================================"
echo ""
echo "Cette action va SUPPRIMER tous les candidats de la base !"
echo ""
read -p "Êtes-vous sûr ? (tapez 'oui' pour confirmer): " CONFIRM

if [ "$CONFIRM" != "oui" ]; then
    echo "❌ Opération annulée"
    exit 0
fi

echo ""
echo "🗑️  Suppression en cours..."

# Compter avant suppression
BEFORE=$(docker exec seeg-mongodb mongosh \
  -u Sevan -p "SevanSeeg2025" \
  --authenticationDatabase admin \
  SEEG-AI \
  --quiet \
  --eval "db.candidats.countDocuments()")

echo "📊 Documents avant: $BEFORE"

# Supprimer
docker exec seeg-mongodb mongosh \
  -u Sevan -p "SevanSeeg2025" \
  --authenticationDatabase admin \
  SEEG-AI \
  --quiet \
  --eval "db.candidats.deleteMany({})"

# Compter après suppression
AFTER=$(docker exec seeg-mongodb mongosh \
  -u Sevan -p "SevanSeeg2025" \
  --authenticationDatabase admin \
  SEEG-AI \
  --quiet \
  --eval "db.candidats.countDocuments()")

echo "📊 Documents après: $AFTER"
echo ""
echo "✅ Base nettoyée ! ($BEFORE documents supprimés)"

