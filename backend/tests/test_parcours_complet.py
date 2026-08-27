"""
Test d'intégration couvrant le parcours principal décrit dans le cahier des
charges : profil -> création de groupe -> plusieurs groupes -> événement ->
statut personnel -> commentaire.

Utilise mongomock-motor pour simuler MongoDB sans base réelle.
"""

import asyncio

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from mongomock_motor import AsyncMongoMockClient

from app.database import mongodb as mongodb_module


@pytest_asyncio.fixture
async def client():
    # Remplace la connexion Mongo réelle par un mock en mémoire.
    mongodb_module.mongodb.client = AsyncMongoMockClient()
    mongodb_module.mongodb.db = mongodb_module.mongodb.client["eventlink_test"]

    from app.main import app  # importé après le patch pour capturer le mock

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_parcours_complet(client: AsyncClient):
    # 1. Création du profil (première utilisation)
    resp = await client.post("/auth/profil", json={"prenom": "Richnel", "nom": "EGUE"})
    assert resp.status_code == 201
    data = resp.json()
    token = data["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Pas encore de groupe
    resp = await client.get("/groupes/mes-groupes", headers=headers)
    assert resp.status_code == 200
    assert resp.json() == []

    # 3. Création d'un premier groupe
    resp = await client.post("/groupes/creer", json={"nom": "Groupe INSPEI"}, headers=headers)
    assert resp.status_code == 201
    groupe_inspei = resp.json()
    assert groupe_inspei["nombre_membres"] == 1
    code_invitation = groupe_inspei["code_invitation"]
    assert len(code_invitation) == 6

    # 4. Création d'un second groupe -> l'utilisateur doit avoir 2 groupes
    resp = await client.post("/groupes/creer", json={"nom": "Groupe Aventure"}, headers=headers)
    assert resp.status_code == 201

    resp = await client.get("/groupes/mes-groupes", headers=headers)
    noms = sorted(g["nom"] for g in resp.json())
    assert noms == ["Groupe Aventure", "Groupe INSPEI"]

    # 5. Un second utilisateur rejoint le groupe INSPEI via le code
    resp = await client.post("/auth/profil", json={"prenom": "Alice", "nom": "K."})
    token_alice = resp.json()["access_token"]
    headers_alice = {"Authorization": f"Bearer {token_alice}"}

    resp = await client.post(
        "/groupes/rejoindre", json={"code_invitation": code_invitation}, headers=headers_alice
    )
    assert resp.status_code == 200
    assert resp.json()["nombre_membres"] == 2

    # 6. Alice ne doit voir QUE le groupe INSPEI (pas Aventure)
    resp = await client.get("/groupes/mes-groupes", headers=headers_alice)
    noms_alice = [g["nom"] for g in resp.json()]
    assert noms_alice == ["Groupe INSPEI"]

    group_id = groupe_inspei["_id"]

    # 7. Création d'un événement par Richnel dans Groupe INSPEI
    resp = await client.post(
        f"/events?groupe_id={group_id}",
        json={
            "lien": "https://example.com/hackathon",
            "description": "Hackathon IA à ne pas manquer",
            "categorie": "hackathon",
        },
        headers=headers,
    )
    assert resp.status_code == 201
    event = resp.json()
    event_id = event["_id"]
    assert event["auteur"]["prenom"] == "Richnel"
    assert event["mon_statut"] is None

    # 8. Statut personnel : Richnel -> inscrit, Alice -> à voir (indépendants)
    resp = await client.patch(f"/events/{event_id}/statut", json={"statut": "inscrit"}, headers=headers)
    assert resp.status_code == 200

    resp = await client.patch(f"/events/{event_id}/statut", json={"statut": "a_voir"}, headers=headers_alice)
    assert resp.status_code == 200

    resp = await client.get(f"/events/{event_id}", headers=headers)
    assert resp.json()["mon_statut"] == "inscrit"

    resp = await client.get(f"/events/{event_id}", headers=headers_alice)
    assert resp.json()["mon_statut"] == "a_voir"

    # 9. Commentaire d'Alice
    resp = await client.post(
        f"/events/{event_id}/commentaires", json={"texte": "Ça a l'air génial !"}, headers=headers_alice
    )
    assert resp.status_code == 201
    assert resp.json()["prenom"] == "Alice"

    resp = await client.get(f"/events/{event_id}/commentaires", headers=headers)
    assert len(resp.json()) == 1

    # 10. Alice ne peut pas accéder au groupe "Aventure" auquel elle n'appartient pas
    resp = await client.get(f"/groupes/mes-groupes", headers=headers_alice)
    aventure_id = None
    resp2 = await client.get("/groupes/mes-groupes", headers=headers)
    for g in resp2.json():
        if g["nom"] == "Groupe Aventure":
            aventure_id = g["_id"]
    resp = await client.get(f"/events?groupe_id={aventure_id}", headers=headers_alice)
    assert resp.status_code == 403
