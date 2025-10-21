#!/usr/bin/env python
"""
Script de vérification de la configuration SEEG-AI
"""
import sys
import os
from pathlib import Path

# Couleurs pour le terminal
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'


def print_header(text):
    print(f"\n{BLUE}{'=' * 60}{RESET}")
    print(f"{BLUE}{text}{RESET}")
    print(f"{BLUE}{'=' * 60}{RESET}\n")


def print_success(text):
    print(f"{GREEN}✓{RESET} {text}")


def print_error(text):
    print(f"{RED}✗{RESET} {text}")


def print_warning(text):
    print(f"{YELLOW}⚠{RESET} {text}")


def check_python_version():
    """Vérifie la version de Python"""
    version = sys.version_info
    if version.major == 3 and version.minor >= 11:
        print_success(f"Python {version.major}.{version.minor}.{version.micro}")
        return True
    else:
        print_error(f"Python {version.major}.{version.minor} (requis: 3.11+)")
        return False


def check_env_file():
    """Vérifie l'existence du fichier .env"""
    if Path(".env").exists():
        print_success("Fichier .env trouvé")
        return True
    else:
        print_error("Fichier .env non trouvé")
        print_warning("  Créez un fichier .env depuis env_template.txt")
        return False


def check_env_variables():
    """Vérifie les variables d'environnement critiques"""
    required_vars = [
        "AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT",
        "AZURE_DOCUMENT_INTELLIGENCE_KEY",
        "SUPABASE_SERVICE_ROLE_KEY",
        "MONGODB_CONNECTION_STRING"
    ]
    
    # Charger les variables depuis .env si présent
    if Path(".env").exists():
        from dotenv import load_dotenv
        load_dotenv()
    
    all_ok = True
    for var in required_vars:
        value = os.getenv(var)
        if value and len(value) > 10:
            print_success(f"{var} configuré")
        else:
            print_error(f"{var} manquant ou invalide")
            all_ok = False
    
    return all_ok


def check_dependencies():
    """Vérifie que les dépendances sont installées"""
    dependencies = [
        "fastapi",
        "uvicorn",
        "pydantic",
        "pymongo",
        "azure",
        "supabase",
        "loguru",
        "pytest"
    ]
    
    all_ok = True
    for dep in dependencies:
        try:
            __import__(dep)
            print_success(f"{dep} installé")
        except ImportError:
            print_error(f"{dep} non installé")
            all_ok = False
    
    return all_ok


def check_directories():
    """Vérifie que les dossiers nécessaires existent"""
    directories = ["data", "temp", "logs"]
    
    all_ok = True
    for directory in directories:
        path = Path(directory)
        if path.exists():
            print_success(f"Dossier {directory}/ présent")
        else:
            print_warning(f"Dossier {directory}/ manquant (sera créé)")
            path.mkdir(parents=True, exist_ok=True)
    
    return True


def check_docker():
    """Vérifie que Docker est installé"""
    import subprocess
    try:
        result = subprocess.run(
            ["docker", "--version"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            version = result.stdout.strip()
            print_success(f"Docker installé: {version}")
            return True
        else:
            print_error("Docker non trouvé")
            return False
    except FileNotFoundError:
        print_error("Docker non installé")
        return False


def check_data_files():
    """Vérifie la présence de fichiers JSON dans data/"""
    data_path = Path("data")
    if not data_path.exists():
        print_warning("Dossier data/ vide")
        return False
    
    json_files = list(data_path.glob("*.json"))
    if json_files:
        print_success(f"{len(json_files)} fichier(s) JSON trouvé(s) dans data/")
        for file in json_files:
            print(f"    - {file.name}")
        return True
    else:
        print_warning("Aucun fichier JSON dans data/")
        print_warning("  Ajoutez des fichiers JSON pour traiter des candidatures")
        return False


def main():
    """Fonction principale"""
    print_header("🔍 VÉRIFICATION DE LA CONFIGURATION SEEG-AI")
    
    checks = []
    
    # Vérification Python
    print_header("1. Version Python")
    checks.append(("Python", check_python_version()))
    
    # Vérification fichiers de config
    print_header("2. Configuration")
    checks.append(("Fichier .env", check_env_file()))
    checks.append(("Variables d'environnement", check_env_variables()))
    
    # Vérification dépendances
    print_header("3. Dépendances Python")
    checks.append(("Dépendances", check_dependencies()))
    
    # Vérification structure
    print_header("4. Structure du projet")
    checks.append(("Dossiers", check_directories()))
    checks.append(("Fichiers de données", check_data_files()))
    
    # Vérification Docker
    print_header("5. Docker")
    checks.append(("Docker", check_docker()))
    
    # Résumé
    print_header("📊 RÉSUMÉ")
    
    total = len(checks)
    passed = sum(1 for _, result in checks if result)
    failed = total - passed
    
    for name, result in checks:
        status = f"{GREEN}✓{RESET}" if result else f"{RED}✗{RESET}"
        print(f"{status} {name}")
    
    print(f"\n{GREEN}{passed}/{total}{RESET} vérifications passées")
    
    if failed > 0:
        print(f"{RED}{failed}/{total}{RESET} vérifications échouées")
        print(f"\n{YELLOW}Action requise:{RESET}")
        print("  1. Installez les dépendances: pip install -r requirements.txt")
        print("  2. Créez votre fichier .env depuis env_template.txt")
        print("  3. Configurez vos credentials Azure et Supabase")
        return 1
    else:
        print(f"\n{GREEN}✅ Configuration complète !{RESET}")
        print(f"\n{BLUE}Prochaines étapes:{RESET}")
        print("  1. Lancez MongoDB: docker-compose up -d mongodb")
        print("  2. Testez l'API: python run_api.py")
        print("  3. Traitez les candidatures: python main.py")
        return 0


if __name__ == "__main__":
    sys.exit(main())

