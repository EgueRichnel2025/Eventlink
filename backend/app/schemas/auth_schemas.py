from datetime import datetime

from pydantic import BaseModel, Field

from app.utils.objectid import PyObjectId


class CreerProfilRequest(BaseModel):
    prenom: str = Field(min_length=1, max_length=50)
    nom: str = Field(min_length=1, max_length=50)


class UserPublic(BaseModel):
    id: PyObjectId = Field(alias="_id")
    prenom: str
    nom: str
    photo_url: str | None = None
    created_at: datetime

    model_config = {"populate_by_name": True}


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserPublic


class RefreshRequest(BaseModel):
    refresh_token: str


class AccessTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UpdateProfilRequest(BaseModel):
    prenom: str | None = Field(default=None, min_length=1, max_length=50)
    nom: str | None = Field(default=None, min_length=1, max_length=50)
    photo_url: str | None = None
