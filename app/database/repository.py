from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database.connection import engine
from app.database.models import IngestionRun


# Persist a single ingestion run into PostgreSQL
def save_ingestion_run(data):
    with Session(engine) as session:

        # Map dictionary data to SQLAlchemy model
        run = IngestionRun(**data)

        # Add record to transaction
        session.add(run)

        # Commit changes to database
        session.commit()


# Return the most recent ingestion runs from PostgreSQL
# Used by the dashboard instead of in-memory storage
def get_latest_ingestion_runs(limit: int = 10):
    with Session(engine) as session:
        statement = (
            select(IngestionRun)
            .order_by(IngestionRun.started_at.desc())
            .limit(limit)
        )
        return session.execute(statement).scalars().all()