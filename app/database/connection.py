from sqlalchemy import create_engine

from app.config import (
    DB_HOST,
    DB_PORT,
    DB_NAME,
    DB_USER,
    DB_SECRET_ARN,
)
from app.database.models import Base
from app.aws.secrets import get_db_password


############################################
# Database engine
############################################
# Engine is created lazily so that AWS Secrets Manager
# lookup happens at runtime, not at import time.
_engine = None


def get_engine():
    global _engine

    if _engine is None:
        # Fetch database password securely from AWS Secrets Manager
        db_password = get_db_password(DB_SECRET_ARN)

        # Build PostgreSQL connection URL
        database_url = (
            f"postgresql://{DB_USER}:{db_password}"
            f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
        )

        _engine = create_engine(database_url, echo=True)

    return _engine


############################################
# Create tables
############################################
# Create database tables from SQLAlchemy models (MVP approach)
def create_tables():
    engine = get_engine()
    Base.metadata.create_all(bind=engine)