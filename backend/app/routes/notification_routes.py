from pydantic import BaseModel
from bson import ObjectId
from fastapi import APIRouter, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database.mongodb import get_database
from app.services import notification_service
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/notifications", tags=["Notifications"])


class RegisterTokenRequest(BaseModel):
    fcm_token: str


@router.post("/register-token", response_model=dict)
async def enregistrer_token(
    payload: RegisterTokenRequest,
    user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    await notification_service.enregistrer_token(db, user["_id"], payload.fcm_token)
    return {"success": True}


@router.get("", response_model=list[dict])
async def mes_notifications(
    user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    notifs = await db.notifications.find({"user_id": user["_id"]}).sort("created_at", -1).to_list(length=200)
    for n in notifs:
        n["_id"] = str(n["_id"])
        n["user_id"] = str(n["user_id"])
    return notifs


@router.patch("/{notification_id}/lu", response_model=dict)
async def marquer_lu(
    notification_id: str,
    user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    await db.notifications.update_one(
        {"_id": ObjectId(notification_id), "user_id": user["_id"]}, {"$set": {"lu": True}}
    )
    return {"success": True}
