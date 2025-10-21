#!/bin/bash
# Script pour afficher les statistiques MongoDB

echo "📊 Statistiques MongoDB - SEEG-AI"
echo "=================================="
echo ""

echo "📦 Bases de données:"
docker exec seeg-mongodb mongosh \
  -u Sevan -p "SevanSeeg2025" \
  --authenticationDatabase admin \
  --quiet \
  --eval "db.adminCommand('listDatabases').databases.forEach(function(db){print('  - ' + db.name + ' (' + (db.sizeOnDisk/1024/1024).toFixed(2) + ' MB)')})"

echo ""
echo "📁 Collections dans SEEG-AI:"
docker exec seeg-mongodb mongosh \
  -u Sevan -p "SevanSeeg2025" \
  --authenticationDatabase admin \
  SEEG-AI \
  --quiet \
  --eval "db.getCollectionNames().forEach(function(col){print('  - ' + col)})"

echo ""
echo "📄 Nombre de candidatures:"
COUNT=$(docker exec seeg-mongodb mongosh \
  -u Sevan -p "SevanSeeg2025" \
  --authenticationDatabase admin \
  SEEG-AI \
  --quiet \
  --eval "db.candidats.countDocuments()")
echo "  Total: $COUNT documents"

echo ""
echo "🔍 Index:"
docker exec seeg-mongodb mongosh \
  -u Sevan -p "SevanSeeg2025" \
  --authenticationDatabase admin \
  SEEG-AI \
  --quiet \
  --eval "db.candidats.getIndexes().forEach(function(idx){print('  - ' + idx.name + ': ' + JSON.stringify(idx.key))})"

echo ""
echo "💾 Taille de la base:"
docker exec seeg-mongodb mongosh \
  -u Sevan -p "SevanSeeg2025" \
  --authenticationDatabase admin \
  SEEG-AI \
  --quiet \
  --eval "var stats = db.stats(); print('  Storage: ' + (stats.dataSize/1024/1024).toFixed(2) + ' MB')"

echo ""
echo "✅ Statistiques affichées"

