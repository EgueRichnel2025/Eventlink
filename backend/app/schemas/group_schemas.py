from datetime import datetime

from pydantic import BaseModel, Field

from app.utils.objectid import PyObjectId


class CreerGroupeRequest(BaseModel):
    nom: str = Field(min_length=1, max_length=80)


class RejoindreGroupeRequest(BaseModel):
    code_invitation: str = Field(min_length=4, max_length=12)


class GroupePublic(BaseModel):
    id: PyObjectId = Field(alias="_id")
    nom: str
    photo_url: str | None = None
    code_invitation: str
    owner_id: PyObjectId
    created_at: datetime
    nombre_membres: int = 0
    nombre_evenements: int = 0
    mon_role: str | None = None

    model_config = {"populate_by_name": True}


class MembreGroupePublic(BaseModel):
    user_id: PyObjectId
    prenom: str
    nom: str
    photo_url: str | None = None
    role: str
    joined_at: datetime


class ModifierGroupeRequest(BaseModel):
    nom: str | None = Field(default=None, min_length=1, max_length=80)
    photo_url: str | None = None
