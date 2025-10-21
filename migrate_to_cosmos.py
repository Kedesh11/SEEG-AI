"""
Script de migration robuste vers Cosmos DB
Gère automatiquement le throttling, les duplicata et la reprise
"""
import json
import time
import sys
from pymongo import MongoClient
from pymongo.errors import DuplicateKeyError, ServerSelectionTimeoutError
from pathlib import Path

class CosmosDBMigrator:
    def __init__(self, connection_string, source_file="candidats_export.json"):
        self.connection_string = connection_string
        self.source_file = source_file
        self.client = None
        self.db = None
        self.collection = None
        self.stats = {
            "total": 0,
            "imported": 0,
            "duplicates": 0,
            "errors": 0,
            "retries": 0
        }
    
    def connect(self):
        """Connexion à Cosmos DB"""
        print("\n" + "=" * 60)
        print("MIGRATION VERS COSMOS DB")
        print("=" * 60 + "\n")
        
        print("1. Connexion à Cosmos DB...")
        try:
            self.client = MongoClient(
                self.connection_string,
                serverSelectionTimeoutMS=10000,
                connectTimeoutMS=10000
            )
            self.db = self.client["SEEG-AI"]
            self.collection = self.db["candidats"]
            
            # Test de connexion
            self.collection.find_one()
            print("   ✓ Connecté !\n")
            return True
        except Exception as e:
            print(f"   ✗ Erreur de connexion: {e}\n")
            return False
    
    def load_data(self):
        """Charge les données depuis le fichier JSON"""
        print(f"2. Lecture du fichier {self.source_file}...")
        
        if not Path(self.source_file).exists():
            print(f"   ✗ Fichier {self.source_file} introuvable\n")
            return None
        
        try:
            with open(self.source_file, "r", encoding="utf-8") as f:
                # Le fichier est au format JSONL (une ligne = un document)
                data = [json.loads(line) for line in f if line.strip()]
            
            self.stats["total"] = len(data)
            print(f"   ✓ {len(data)} documents chargés\n")
            return data
        except Exception as e:
            print(f"   ✗ Erreur de lecture: {e}\n")
            return None
    
    def check_existing_data(self):
        """Vérifie les données existantes"""
        try:
            count = self.collection.count_documents({})
            print(f"   Documents existants dans Cosmos DB: {count}")
            return count
        except Exception as e:
            print(f"   ✗ Impossible de compter les documents: {e}")
            return 0
    
    def insert_document(self, document, index):
        """Insert un document avec gestion des erreurs et retry"""
        max_retries = 3
        retry_delay = 2  # secondes
        
        for attempt in range(max_retries):
            try:
                self.collection.insert_one(document)
                self.stats["imported"] += 1
                return True
                
            except DuplicateKeyError:
                # Duplicata - normal, on ignore
                self.stats["duplicates"] += 1
                return True
                
            except Exception as e:
                error_msg = str(e)
                
                # Throttling (429) - on attend et on réessaye
                if "429" in error_msg or "TooManyRequests" in error_msg or "16500" in error_msg:
                    if attempt < max_retries - 1:
                        self.stats["retries"] += 1
                        wait_time = retry_delay * (attempt + 1)
                        print(f"\n   ⚠️  Throttling détecté (doc {index}) - pause de {wait_time}s...")
                        time.sleep(wait_time)
                        continue
                    else:
                        self.stats["errors"] += 1
                        print(f"\n   ✗ Échec après {max_retries} tentatives (doc {index})")
                        return False
                
                # Autre erreur
                else:
                    self.stats["errors"] += 1
                    if self.stats["errors"] <= 3:  # N'afficher que les 3 premières erreurs
                        print(f"\n   ✗ Erreur doc {index}: {error_msg[:100]}")
                    return False
        
        return False
    
    def migrate(self, data):
        """Effectue la migration avec barre de progression"""
        print("3. Migration des documents...")
        print(f"   Mode: Document par document avec gestion des erreurs")
        print(f"   Délai: 300ms entre chaque document\n")
        
        total = len(data)
        progress_interval = max(1, total // 20)  # Afficher toutes les 5%
        
        for i, document in enumerate(data, 1):
            self.insert_document(document, i)
            
            # Afficher la progression
            if i % progress_interval == 0 or i == total:
                percentage = (i / total) * 100
                imported = self.stats["imported"]
                duplicates = self.stats["duplicates"]
                errors = self.stats["errors"]
                print(f"   Progression: {i}/{total} ({percentage:.1f}%) - "
                      f"Importés: {imported}, Duplicata: {duplicates}, Erreurs: {errors}")
            
            # Pause entre chaque document pour éviter le throttling
            if i < total:
                time.sleep(0.3)  # 300ms
        
        print()
    
    def verify(self):
        """Vérifie le résultat de la migration"""
        print("4. Vérification...")
        try:
            final_count = self.collection.count_documents({})
            print(f"   Total dans Cosmos DB: {final_count}/{self.stats['total']}")
            
            if final_count > 0:
                print(f"\n5. Exemples de documents migrés:")
                for idx, doc in enumerate(self.collection.find().limit(5), 1):
                    nom = f"{doc.get('first_name', '')} {doc.get('last_name', '')}"
                    email = doc.get('email', 'N/A')
                    print(f"   {idx}. {nom} - {email}")
            
            return final_count
        except Exception as e:
            print(f"   ✗ Erreur de vérification: {e}")
            return 0
    
    def print_summary(self, final_count):
        """Affiche le résumé de la migration"""
        print("\n" + "=" * 60)
        print("RÉSUMÉ DE LA MIGRATION")
        print("=" * 60)
        
        print(f"\nDocuments traités:      {self.stats['total']}")
        print(f"Nouveaux importés:      {self.stats['imported']}")
        print(f"Duplicata ignorés:      {self.stats['duplicates']}")
        print(f"Erreurs:                {self.stats['errors']}")
        print(f"Tentatives de retry:    {self.stats['retries']}")
        print(f"\nTotal dans Cosmos DB:   {final_count}")
        
        success_rate = ((self.stats['imported'] + self.stats['duplicates']) / self.stats['total']) * 100
        print(f"Taux de succès:         {success_rate:.1f}%")
        
        if final_count == self.stats['total']:
            print("\n✅ MIGRATION 100% RÉUSSIE !")
        elif final_count > 0:
            print(f"\n⚠️  MIGRATION PARTIELLE ({final_count}/{self.stats['total']})")
        else:
            print("\n❌ MIGRATION ÉCHOUÉE")
        
        print("=" * 60 + "\n")
    
    def close(self):
        """Ferme la connexion"""
        if self.client:
            self.client.close()
    
    def run(self):
        """Exécute la migration complète"""
        try:
            # Connexion
            if not self.connect():
                return False
            
            # Vérifier l'état actuel
            existing = self.check_existing_data()
            print()
            
            # Charger les données
            data = self.load_data()
            if not data:
                return False
            
            # Demander confirmation si des données existent déjà
            if existing > 0:
                print(f"⚠️  {existing} documents existent déjà dans Cosmos DB")
                print("   Les duplicata seront automatiquement ignorés\n")
            
            # Migration
            self.migrate(data)
            
            # Vérification
            final_count = self.verify()
            
            # Résumé
            self.print_summary(final_count)
            
            return final_count == self.stats['total']
            
        except KeyboardInterrupt:
            print("\n\n⚠️  Migration interrompue par l'utilisateur")
            print(f"   Documents importés: {self.stats['imported']}")
            print(f"   Vous pouvez relancer le script pour continuer\n")
            return False
            
        except Exception as e:
            print(f"\n❌ Erreur fatale: {e}")
            import traceback
            traceback.print_exc()
            return False
            
        finally:
            self.close()


def main():
    """Point d'entrée principal"""
    # Connection string depuis la ligne de commande ou variable d'environnement
    import os
    
    connection_string = None
    source_file = "candidats_export.json"
    
    # Arguments en ligne de commande
    if len(sys.argv) > 1:
        connection_string = sys.argv[1]
    
    if len(sys.argv) > 2:
        source_file = sys.argv[2]
    
    # Ou depuis variable d'environnement
    if not connection_string:
        from dotenv import load_dotenv
        load_dotenv()
        connection_string = os.getenv("MONGODB_CONNECTION_STRING")
    
    # Vérifier que la connection string est fournie
    if not connection_string:
        print("\n❌ Erreur: Connection string Cosmos DB non fournie")
        print("\nUtilisation:")
        print("  python migrate_to_cosmos.py <connection_string> [fichier.json]")
        print("\nOu définir MONGODB_CONNECTION_STRING dans .env\n")
        sys.exit(1)
    
    # Exécuter la migration
    migrator = CosmosDBMigrator(connection_string, source_file)
    success = migrator.run()
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

