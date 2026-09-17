from datetime import datetime
from enum import Enum
from typing import Dict

from pydantic import BaseModel, Field, HttpUrl

from app.utils.objectid import PyObjectId


class CategorieEvent(str, Enum):
    formation = "formation"
    opportunite = "opportunite"
    hackathon = "hackathon"
    bourse = "bourse"
    evenement = "evenement"
    ressource = "ressource"
    autre = "autre"


class StatutPersonnel(str, Enum):
    a_voir = "a_voir"
    inscrit = "inscrit"
    passe = "passe"


class CreerEventRequest(BaseModel):
    lien: HttpUrl
    description: str = Field(min_length=1, max_length=1000)
    image_url: str | None = None
    categorie: CategorieEvent = CategorieEvent.autre


class ModifierEventRequest(BaseModel):
    lien: HttpUrl | None = None
    description: str | None = Field(default=None, min_length=1, max_length=1000)
    image_url: str | None = None
    categorie: CategorieEvent | None = None


class ChangerStatutRequest(BaseModel):
    statut: StatutPersonnel


class ReactionRequest(BaseModel):
    type: str = Field(min_length=1, max_length=30)


class AuteurPublic(BaseModel):
    user_id: PyObjectId
    prenom: str
    nom: str
    photo_url: str | None = None


class EventPublic(BaseModel):
    id: PyObjectId = Field(alias="_id")
    group_id: PyObjectId
    lien: str
    description: str
    image_url: str | None = None
    categorie: CategorieEvent
    auteur: AuteurPublic
    created_at: datetime
    mon_statut: StatutPersonnel | None = None
    nombre_commentaires: int = 0
    vues: int = 0
    reactions: Dict[str, int] = {}
    user_reaction: str | None = None

    model_config = {"populate_by_name": True}


class MentionRequest(BaseModel):
    mention_type: str = "user"
    user_id: PyObjectId | None = None


class CommentaireRequest(BaseModel):
    texte: str = Field(min_length=1, max_length=500)
    parent_comment_id: PyObjectId | None = None
    mentions: list[MentionRequest] = Field(default_factory=list)


class MentionPublic(BaseModel):
    mention_type: str = "user"
    user_id: PyObjectId | None = None


class CommentairePublic(BaseModel):
    id: PyObjectId = Field(alias="_id")
    event_id: PyObjectId
    user_id: PyObjectId
    prenom: str
    nom: str
    photo_url: str | None = None
    avatar_id: str | None = None
    texte: str
    created_at: datetime
    parent_comment_id: PyObjectId | None = None
    epingle: bool = False
    mentions: list[MentionPublic] = Field(default_factory=list)

    # Réactions du commentaire
    reactions: Dict[str, int] = {}
    user_reaction: str | None = None

    model_config = {"populate_by_name": True}
    