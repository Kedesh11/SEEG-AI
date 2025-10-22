# 🚨 RÉPONSE À VOTRE QUESTION

## ❌ **Problème Identifié**

Le script actuel `migrate_to_cosmos.py` **NE prend PAS en compte automatiquement** les nouvelles migrations depuis `data/Donnees_candidatures_SEEG.json`.

### Pourquoi ?

```python
# migrate_to_cosmos.py ligne 13
def __init__(self, connection_string, source_file="candidats_export.json"):
    # ❌ Lit UNIQUEMENT ce fichier (export MongoDB au format JSONL)
```

**Le script attend un export MongoDB**, pas le fichier JSON source avec vos 40 nouveaux candidats.

---

## ✅ **SOLUTION : Nouveau Script de Migration Directe**

J'ai créé un **nouveau script** qui résout ce problème :

### 📄 `migrate_direct_to_cosmos.py`

Ce script :
- ✅ Lit **directement** depuis `data/Donnees_candidatures_SEEG.json`
- ✅ Télécharge les documents depuis Supabase
- ✅ Effectue l'OCR avec Azure Document Intelligence
- ✅ Pousse **directement** vers Cosmos DB Azure
- ✅ Gère automatiquement les duplicata
- ✅ Peut être relancé sans problème

---

## 🚀 **UTILISATION SIMPLE (1 Commande)**

### Option 1 : Script PowerShell Automatisé (PLUS SIMPLE)

```powershell
# Tout en un !
.\migrate_to_azure.ps1
```

Le script vous demandera quelle méthode utiliser et s'occupera de tout.

### Option 2 : Commande Manuelle

```powershell
# 1. Récupérer la connection string
$connStr = az cosmosdb keys list --name seeg-ai --resource-group seeg-rg --type connection-strings --query "connectionStrings[0].connectionString" --output tsv

# 2. Lancer la migration directe
python migrate_direct_to_cosmos.py "$connStr"
```

---

## 📊 **Ce qui va se passer**

```
Étape 1: Lecture de data/Donnees_candidatures_SEEG.json (40 candidats)
         ↓
Étape 2: Connexion à Cosmos DB Azure
         ↓
Étape 3: Pour chaque candidat:
         ├── Vérifier s'il existe déjà (évite duplicata)
         ├── Télécharger documents depuis Supabase
         ├── Extraction OCR avec Azure
         └── Sauvegarde dans Cosmos DB
         ↓
Étape 4: Rapport détaillé
```

**Durée**: ~30 minutes pour 40 candidats (avec OCR complet)

---

## 📁 **Fichiers Créés**

✅ `migrate_direct_to_cosmos.py` - Script de migration directe  
✅ `migrate_to_azure.ps1` - Script PowerShell automatisé  
✅ `GUIDE_MIGRATION_AZURE.md` - Guide complet détaillé  
✅ `README_MIGRATION.md` - Ce fichier (résumé)  

---

## 🎯 **COMMANDE RECOMMANDÉE**

La solution **la plus simple** pour vous :

```powershell
# Activer l'environnement virtuel
.\env\Scripts\Activate.ps1

# Lancer la migration automatisée
.\migrate_to_azure.ps1
```

Le script va :
1. ✅ Se connecter à Azure
2. ✅ Récupérer automatiquement la connection string Cosmos DB
3. ✅ Vous demander quelle méthode utiliser (choisissez 1)
4. ✅ Traiter les 40 candidats avec OCR
5. ✅ Les pousser vers Cosmos DB Azure
6. ✅ Vérifier que tout est bien en ligne
7. ✅ Afficher un rapport final

---

## ⚠️ **IMPORTANT**

### Prérequis avant de lancer :
- [x] Azure CLI connecté (`az login`)
- [x] Environnement virtuel activé
- [x] Fichier `data/Donnees_candidatures_SEEG.json` présent (40 candidats)
- [x] Credentials Azure Document Intelligence valides
- [x] Cosmos DB Azure accessible

### Coûts :
- **OCR Azure**: ~0.01€ par page
- **40 candidats × 4 docs** = ~160 pages
- **Coût estimé**: 2-3€

---

## 🔍 **Vérification Post-Migration**

Après la migration, vérifiez :

```powershell
# Health check API
curl https://seeg-ai-api.azurewebsites.net/health

# Compter les candidatures
$candidats = Invoke-RestMethod -Uri "https://seeg-ai-api.azurewebsites.net/candidatures"
Write-Host "Total: $($candidats.Count) candidats"
```

---

## 📚 **Comparaison des Scripts**

| Script | Source | Traitement | Usage |
|--------|--------|------------|-------|
| **migrate_to_cosmos.py** (ancien) | `candidats_export.json` (JSONL) | ❌ Pas d'OCR | Migration depuis MongoDB local |
| **migrate_direct_to_cosmos.py** (nouveau) | `data/Donnees_candidatures_SEEG.json` | ✅ OCR complet | Migration directe vers Azure |
| **migrate_to_azure.ps1** (automatique) | Les deux méthodes | Selon choix | Automatisation complète |

---

## ✅ **EN RÉSUMÉ**

### Votre question :
> "Je veux push les nouvelles migrations en local vers Azure"

### La réponse :
**Le script actuel `migrate_to_cosmos.py` ne le fait pas directement.**

**Solution** : Utilisez le nouveau script créé :

```powershell
.\migrate_to_azure.ps1
```

C'est **tout** ! Le script s'occupe de tout pour vous. 🚀

---

## 📞 **Besoin d'Aide ?**

Consultez le guide complet : `GUIDE_MIGRATION_AZURE.md`

Ou lancez simplement :
```powershell
.\migrate_to_azure.ps1
```

Le script est **interactif** et vous guide à chaque étape ! 😊

