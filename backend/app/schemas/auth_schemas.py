from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from app.utils.objectid import PyObjectId


class CreerProfilRequest(BaseModel):
    prenom: str = Field(min_length=1, max_length=50)
    nom: str = Field(min_length=1, max_length=50)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    avatar_id: str | None = None


class ConnexionRequest(BaseModel):
    user_id: PyObjectId
    password: str = Field(min_length=1, max_length=128)


class ConnexionCodeRequest(BaseModel):
    account_code: str = Field(min_length=9, max_length=9)


class UserPublic(BaseModel):
    id: PyObjectId = Field(alias="_id")
    prenom: str
    nom: str
    photo_url: str | None = None
    avatar_id: str | None = None
    account_code: str
    created_at: datetime
    email: EmailStr | None = None

    model_config = {"populate_by_name": True}


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserPublic

    model_config = {"populate_by_name": True}


class RefreshRequest(BaseModel):
    refresh_token: str


class AccessTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

    model_config = {"populate_by_name": True}


class UpdateProfilRequest(BaseModel):
    prenom: str | None = Field(default=None, min_length=1, max_length=50)
    nom: str | None = Field(default=None, min_length=1, max_length=50)
    photo_url: str | None = None
    avatar_id: str | None = None


class DemanderCodeEmailRequest(BaseModel):
    email: EmailStr


class VerifierCodeEmailRequest(BaseModel):
    email: EmailStr
    code: str = Field(
        min_length=6,
        max_length=6,
        pattern=r"^\d{6}$",
    )


class ReinitialiserMotDePasseRequest(BaseModel):
    reset_token: str = Field(min_length=20, max_length=500)
    new_password: str = Field(min_length=8, max_length=128)


class ResetTokenResponse(BaseModel):
    reset_token: str
