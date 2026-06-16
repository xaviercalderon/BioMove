import logging, os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .config import get_settings
from .database import create_tables
from .firebase.firebase_service import init_firebase

settings = get_settings()
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(name)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("🚀 BioMove API v4.0 iniciando...")
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    os.makedirs("models", exist_ok=True)
    os.makedirs("exports", exist_ok=True)
    await create_tables()
    init_firebase()
    logger.info("✅ Sistema listo")
    yield
    logger.info("BioMove API deteniendo...")

app = FastAPI(title="BioMove API", version=settings.VERSION,
              description="Análisis biomecánico con IA — 40 parámetros, 3 roles", lifespan=lifespan)

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True,
                   allow_methods=["*"], allow_headers=["*"])

from .routers import auth_router, users_router, videos_router
from .routers import workouts_router, strength_router, ai_router
from .routers import coach_router, admin_router

app.include_router(auth_router.router)
app.include_router(users_router.router)
app.include_router(videos_router.router)
app.include_router(workouts_router.router)
app.include_router(strength_router.router)
app.include_router(ai_router.router)
app.include_router(coach_router.router)
app.include_router(admin_router.router)

@app.get("/", tags=["Health"])
async def root():
    from .ai.classifier import squat_classifier
    return {"app":"BioMove API","version":settings.VERSION,"status":"running",
            "classifier":squat_classifier.get_info(),"docs":"/docs"}

@app.get("/health", tags=["Health"])
async def health():
    from .ai.classifier import squat_classifier
    return {"status":"healthy","version":settings.VERSION,
            "classifier_ready":squat_classifier.ready,"classifier_version":squat_classifier.version}
