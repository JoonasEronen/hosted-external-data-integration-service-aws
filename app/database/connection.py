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


# Fetch database password securely from AWS Secrets Manager
db_password = get_db_password(DB_SECRET_ARN)

# Build PostgreSQL connection URL from runtime config and secret
DATABASE_URL = (
    f"postgresql://{DB_USER}:{db_password}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# SQLAlchemy engine manages DB connections and pooling
engine = create_engine(DATABASE_URL, echo=True)


# Create database tables from SQLAlchemy models (MVP approach)
# In production this would typically be handled via migrations
def create_tables():
    Base.metadata.create_all(bind=engine)