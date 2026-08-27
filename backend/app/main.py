"""
Point d'entrée de l'API EventLink.
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config.settings import settings
from app.database.mongodb import close_mongo_connection, connect_to_mongo
from app.routes import auth_routes, event_routes, groupe_routes, notification_routes
from app.services.notification_service import init_firebase

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("eventlink")


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_to_mongo()
    init_firebase()  # ne lève jamais d'exception, même si Firebase n'est pas configuré
    yield
    await close_mongo_connection()


app = FastAPI(
    title="EventLink API",
    description="API backend pour EventLink — centraliser les opportunités partagées en groupe.",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": "Données invalides", "errors": exc.errors()},
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})


app.include_router(auth_routes.router)
app.include_router(groupe_routes.router)
app.include_router(event_routes.router)
app.include_router(notification_routes.router)


@app.get("/", tags=["Santé"])
async def racine():
    return {"app": "EventLink API", "status": "ok"}


@app.get("/health", tags=["Santé"])
async def health():
    return {"status": "ok"}
