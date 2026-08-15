"""
routes/event_routes.py
Rôle : endpoints liés aux events (créer, lister, changer statut, commenter).
C'est le fichier le plus important du backend.

Responsable suggéré : Elie
"""

from fastapi import APIRouter
from app.schemas.event_schema import EventCreate, EventStatutUpdate, CommentaireCreate

router = APIRouter()


@router.post("/")
async def creer_event(event: EventCreate, groupe_id: str, user_id: str):
    """
    Crée un nouvel event (bouton "Ajouter" côté app).

    TODO:
    - construire l'objet event à partir des données reçues (lien, description, image_url)
    - ajouter groupe_id, ajoute_par=user_id, date_ajout=maintenant
    - initialiser statut_membres et commentaires (listes/dicos vides)
    - enregistrer en base (collection "events")
    - déclencher l'envoi de notification à tout le groupe (voir fcm_service.py)
    - retourner l'event créé
    """
    pass


@router.get("/")
async def lister_events(groupe_id: str):
    """
    Liste tous les events d'un groupe.

    TODO:
    - chercher tous les events où groupe_id correspond
    - les trier du plus récent au plus ancien
    - retourner la liste
    """
    pass


@router.get("/{event_id}")
async def get_event(event_id: str):
    """
    Récupère le détail complet d'un event (avec ses commentaires).

    TODO:
    - chercher l'event par son _id
    - si non trouvé, retourner une erreur claire
    - retourner l'event complet
    """
    pass


@router.patch("/{event_id}/statut")
async def changer_statut(event_id: str, data: EventStatutUpdate, user_id: str):
    """
    Change le statut d'un membre sur un event (a_voir / inscrit / passe).

    TODO:
    - chercher l'event par son _id
    - mettre à jour statut_membres[user_id] avec le nouveau statut
    - sauvegarder en base
    - retourner l'event mis à jour
    """
    pass


@router.post("/{event_id}/commentaires")
async def ajouter_commentaire(event_id: str, commentaire: CommentaireCreate, user_id: str):
    """
    Ajoute un commentaire sur un event.

    TODO:
    - construire l'objet commentaire (user_id, texte, date=maintenant)
    - l'ajouter à la liste des commentaires de l'event en base
    - retourner le commentaire créé (ou l'event mis à jour)
    """
    pass
