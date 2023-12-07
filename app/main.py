from pathlib import Path

from fastapi import FastAPI

from app.config import FRONTEND_DIR
from app.frontend import mount_frontend

app = FastAPI()

mount_frontend(app, build_dir=Path(FRONTEND_DIR))
