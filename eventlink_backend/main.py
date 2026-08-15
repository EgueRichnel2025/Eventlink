"""
main.py
Rôle : point d'entrée de l'API. Crée l'application FastAPI et
branche toutes les routes (auth, groupes, events).

Responsable suggéré : toi (Richnel) en coordination avec Dine/Elie/Référil
"""

from fastapi import FastAPI

app = FastAPI(title="EventLink API")

# TODO: importer les routers depuis app/routes/ (auth_routes, groupe_routes, event_routes)
# from app.routes import auth_routes, groupe_routes, event_routes

# TODO: brancher chaque router sur l'app avec app.include_router(...)
# Exemple : app.include_router(event_routes.router, prefix="/events", tags=["events"])


@app.get("/")
def health_check():
    """
    Endpoint simple pour vérifier que le serveur tourne.
    Ne pas modifier, sert de test rapide.
    """
    return {"status": "EventLink API en ligne"}
