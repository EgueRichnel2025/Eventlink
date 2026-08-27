"""
Wrapper permettant à Pydantic v2 de valider/sérialiser les ObjectId MongoDB
comme de simples chaînes de caractères côté API.
"""

from typing import Annotated

from bson import ObjectId
from pydantic import BeforeValidator


def _validate_object_id(value: object) -> str:
    if isinstance(value, ObjectId):
        return str(value)
    if isinstance(value, str) and ObjectId.is_valid(value):
        return value
    raise ValueError(f"'{value}' n'est pas un ObjectId MongoDB valide")


PyObjectId = Annotated[str, BeforeValidator(_validate_object_id)]
