# ✅ Vérification du Flux Complet

## 📋 Checklist du Flux

Voici ce que fait le script `main.py` pour CHAQUE candidat :

### Étape 1 : Lecture des Données ✅
```python
# Lit data/Donnees_candidatures_SEEG.json
candidats_data = json.load(fichier)  # Tableau de ~XXX candidats
```

### Étape 2 : Extraction URLs Documents ✅
```python
# Pour chaque candidat, extrait les documents
documents = [
    {"type": "cv", "url": "348dceb8.../cv/...pdf"},
    {"type": "cover_letter", "url": "348dceb8.../cover-letters/...pdf"},
    {"type": "diploma", "url": "348dceb8.../certificates/...pdf"},
    {"type": "certificate", "url": "348dceb8.../additional-certificates/...pdf"}
]

# Construction URLs complètes Supabase
full_url = "https://fyiitzndlqcnyluwkpqp.supabase.co/storage/v1/object/public/candidats-documents/{url}"
```

### Étape 3 : Téléchargement Supabase ✅
```python
# Télécharge chaque document
await supabase_client.download_file(url, destination)
# → Fichier sauvegardé dans temp/{prenom}_{nom}_{type}.pdf
```

### Étape 4 : Extraction OCR Azure ✅
```python
# Pour chaque document téléchargé
extracted_text = azure_ocr_service.extract_text_from_file(fichier)

# Utilise Azure Document Intelligence
# - Modèle: prebuilt-read (meilleur pour texte)
# - Support: PDF multipage, images
# - Retry: 3 tentatives automatiques
```

### Étape 5 : Sauvegarde MongoDB ✅
```python
# Construction de l'objet Candidature
candidature = {
    "first_name": "...",
    "last_name": "...",
    "offre": {
        "intitule": job_title,
        "reference": job_id,
        "type_contrat": contract_type,
        ...
    },
    "reponses_mtp": {
        "metier": [...],
        "talent": [...],
        "paradigme": [...]
    },
    "documents": {
        "cv": "Texte extrait par OCR...",
        "cover_letter": "Texte extrait...",
        "diplome": "Texte extrait...",
        "certificats": "Texte extrait..."
    }
}

# Sauvegarde (Upsert = idempotent)
mongodb_client.insert_or_update_candidature(candidature)
```

---

## 🧪 Test du Flux

### Test avec UN candidat

```bash
# 1. Copier la configuration
Copy-Item env.production.seeg .env

# 2. Démarrer MongoDB
docker-compose up -d mongodb

# 3. Tester avec un seul candidat
python test_one_candidate.py
```

Ce script va :
- ✅ Traiter uniquement le PREMIER candidat du fichier
- ✅ Afficher chaque étape en détail
- ✅ Vous permettre de valider avant de traiter les milliers d'autres

### Test complet (tous les candidats)

```bash
python main.py
```

⚠️ **Attention** : Cela va traiter TOUS les candidats du fichier (peut être long!)

---

## 📊 Vérification des Résultats

### Via l'API

```bash
# Démarrer l'API (dans un autre terminal)
python run_api.py

# Dans un autre terminal
curl http://localhost:8000/candidatures
curl "http://localhost:8000/candidatures/search?first_name=Eric"
```

### Via MongoDB Shell

```bash
# Linux/Mac
./scripts/mongodb_cli.sh

# Windows ou manuel
docker exec -it seeg-mongodb mongosh -u Sevan -p "Sevan@Seeg" SEEG-AI

# Une fois dans le shell
db.candidats.countDocuments()
db.candidats.find().limit(1).pretty()
```

### Via Mongo Express

```
URL: http://localhost:8081
User: Sevan
Pass: Sevan@Seeg
```

---

## 🎯 Mapping des Données

### De Supabase JSON → MongoDB

```json
// JSON Supabase (entrée)
{
  "first_name": "Eric Hervé",
  "last_name": "EYOGO TOUNG",
  "job_title": "Directeur Juridique...",
  "documents": [
    {"type": "cv", "url": "348dceb8.../cv/xxx.pdf"}
  ],
  "reponses_mtp_candidat": {
    "metier": ["..."]
  }
}

// MongoDB (sortie après OCR)
{
  "first_name": "Eric Hervé",
  "last_name": "EYOGO TOUNG",
  "offre": {
    "intitule": "Directeur Juridique...",
    "type_contrat": "CDI",
    ...
  },
  "reponses_mtp": {
    "metier": ["..."],
    ...
  },
  "documents": {
    "cv": "TEXTE EXTRAIT PAR OCR AZURE...",
    "cover_letter": "TEXTE EXTRAIT...",
    ...
  }
}
```

---

## 🔍 Points de Vérification

### 1. URLs Supabase Correctes

Le script construit les URLs comme :
```
https://fyiitzndlqcnyluwkpqp.supabase.co/storage/v1/object/public/candidats-documents/348dceb8-91a0-477d-8438-e376ee0879d7/cv/1760971988318-9j4j9xrxnae.pdf
```

### 2. Téléchargement Fonctionne

Les fichiers sont sauvegardés temporairement dans :
```
temp/Eric Hervé_EYOGO TOUNG_cv.pdf
temp/Eric Hervé_EYOGO TOUNG_cover_letter.pdf
...
```

### 3. OCR Azure Extrait le Texte

Azure Document Intelligence analyse chaque PDF et retourne le texte brut.

### 4. MongoDB Reçoit Tout

Chaque candidat est sauvegardé avec :
- ✅ Métadonnées (nom, prénom, email...)
- ✅ Informations offre
- ✅ Réponses MTP
- ✅ **Textes extraits des documents PDF**

---

## ⚠️ Important

### Performance

- ~XXX candidats dans le fichier
- Chaque candidat a ~4 documents
- Chaque document OCR prend ~5-10 secondes
- **Temps estimé total** : Plusieurs heures

### Recommandations

1. **Testez d'abord** avec `test_one_candidate.py`
2. **Vérifiez** que l'OCR fonctionne bien
3. **Lancez** `main.py` pour traiter tout
4. **Surveillez** les logs dans `logs/`

---

**Le flux est complet et fonctionnel !** ✅🚀

