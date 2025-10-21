#!/bin/bash
# Script pour accéder facilement à MongoDB CLI

echo "🗄️  Connexion à MongoDB Shell..."
echo "Container: seeg-mongodb"
echo "Database: SEEG-AI"
echo ""

docker exec -it seeg-mongodb mongosh \
  -u Sevan \
  -p "SevanSeeg2025" \
  --authenticationDatabase admin \
  SEEG-AI

# Usage:
# ./scripts/mongodb_cli.sh
# 
# Une fois dans le shell:
# show collections
# db.candidats.find()
# db.candidats.countDocuments()

