from sqlalchemy import create_engine
from app.config import (
    DB_HOST,
    DB_PORT,
    DB_NAME,
    DB_USER,
    DB_PASSWORD,
)
from app.database.models import Base

# Build PostgreSQL connection URL
DATABASE_URL = (
    f"postgresql://{DB_USER}:{DB_PASSWORD}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# SQLAlchemy engine
engine = create_engine(DATABASE_URL, echo=True)

# Create database tables from SQLAlchemy models (MVP approach)
# In production this would typically be handled via migrations
def create_tables():
    Base.metadata.create_all(bind=engine)