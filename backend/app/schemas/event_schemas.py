from datetime import datetime
from enum import Enum

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

    model_config = {"populate_by_name": True}


class CommentaireRequest(BaseModel):
    texte: str = Field(min_length=1, max_length=500)


class CommentairePublic(BaseModel):
    id: PyObjectId = Field(alias="_id")
    event_id: PyObjectId
    user_id: PyObjectId
    prenom: str
    nom: str
    photo_url: str | None = None
    texte: str
    created_at: datetime

    model_config = {"populate_by_name": True}
