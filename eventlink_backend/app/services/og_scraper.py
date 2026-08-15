"""
services/og_scraper.py

⚠️ FICHIER NON PRIORITAIRE (V2) — pas utilisé dans le MVP actuel.
En V1, c'est le membre qui remplit lui-même titre/description/image.
Ce fichier reste ici pour plus tard, si on veut automatiser l'extraction
des infos d'un lien.

Responsable suggéré : à voir plus tard, pas urgent.
"""

import httpx
from bs4 import BeautifulSoup


async def extraire_infos_lien(url: str) -> dict:
    """
    (V2 - non prioritaire) Va chercher les balises Open Graph d'une page
    web (og:title, og:description, og:image) pour pré-remplir un event.

    TODO (plus tard):
    - faire une requête GET sur l'url avec httpx
    - parser le HTML avec BeautifulSoup
    - extraire les balises meta og:title, og:description, og:image
    - retourner un dict {"titre": ..., "description": ..., "image_url": ...}
    - gérer le cas où le site bloque le scraping (retourner un dict vide)
    """
    pass
