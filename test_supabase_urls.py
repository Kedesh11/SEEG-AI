"""
Script pour tester différents formats d'URLs Supabase
"""
import httpx
import asyncio

# URL de base Supabase
SUPABASE_URL = "https://fyiitzndlqcnyluwkpqp.supabase.co"

# Chemin relatif d'un document (depuis le JSON)
RELATIVE_PATH = "348dceb8-91a0-477d-8438-e376ee0879d7/cv/1760971988318-9j4j9xrxnae.pdf"

# Différents noms de buckets possibles
BUCKET_NAMES = [
    "candidats-documents",
    "documents",
    "candidats",
    "files",
    "uploads",
    "seeg-documents",
    "applications"
]

async def test_url(url):
    """Teste une URL"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.head(url, timeout=10.0)
            return response.status_code
    except Exception as e:
        return f"Erreur: {e}"

async def main():
    print("🔍 Test des URLs Supabase possibles\n")
    print("=" * 80)
    
    for bucket in BUCKET_NAMES:
        # Format public
        url = f"{SUPABASE_URL}/storage/v1/object/public/{bucket}/{RELATIVE_PATH}"
        print(f"\nTest: {bucket}")
        print(f"URL: {url}")
        
        status = await test_url(url)
        if status == 200:
            print(f"✅ TROUVÉ ! Status: {status}")
            print(f"\n🎯 Le bucket correct est: {bucket}")
            return bucket
        else:
            print(f"❌ Échec - Status: {status}")
    
    print("\n" + "=" * 80)
    print("❌ Aucun bucket ne fonctionne avec ce format")
    print("\n💡 Solutions:")
    print("   1. Vérifiez le nom du bucket dans Supabase")
    print("   2. Vérifiez que le bucket est public")
    print("   3. Vérifiez les permissions du bucket")

if __name__ == "__main__":
    asyncio.run(main())

