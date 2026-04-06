from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database.connection import get_engine
from app.database.models import IngestionRun


############################################
# Repository layer
############################################
# Handles database persistence and queries
# for ingestion run metadata.
#
# This layer isolates SQLAlchemy usage from
# the rest of the application.


############################################
# Save ingestion run
############################################
# Persist a single ingestion run into PostgreSQL.
# Called by the ingestion service after each run.
def save_ingestion_run(data):
    # Open SQLAlchemy session
    with Session(get_engine()) as session:

        # Map dictionary data to SQLAlchemy model
        run = IngestionRun(**data)

        # Add record to transaction
        session.add(run)

        # Commit changes to database
        session.commit()


############################################
# Get latest ingestion runs
############################################
# Return most recent ingestion runs ordered by start time.
# Used by dashboard endpoint to display ingestion history.
def get_latest_ingestion_runs(limit: int = 10):
    # Open SQLAlchemy session
    with Session(get_engine()) as session:

        # Build query ordered by newest first
        statement = (
            select(IngestionRun)
            .order_by(IngestionRun.started_at.desc())
            .limit(limit)
        )

        # Execute query and return list of results
        return session.execute(statement).scalars().all()