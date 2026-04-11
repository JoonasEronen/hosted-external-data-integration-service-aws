from datetime import datetime

from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import Integer, String, DateTime, JSON


############################################
# SQLAlchemy base model
############################################
# Base class for all database models.
# SQLAlchemy uses this metadata to create tables
# and manage schema definitions.
class Base(DeclarativeBase):
    pass


############################################
# Ingestion run model
############################################
# Represents a single ingestion run of the
# external data integration service.
#
# Each record stores operational metadata:
# - when ingestion started
# - when it finished
# - status
# - number of records fetched
# - error details
class IngestionRun(Base):
    __tablename__ = "ingestion_runs"

    ############################################
    # Primary key
    ############################################
    # Unique identifier for each ingestion run
    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    ############################################
    # Source metadata
    ############################################
    # Name of the external data source
    # (weather API, traffic API, etc.)
    source_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    ############################################
    # Run status
    ############################################
    # Ingestion status:
    # - success
    # - failed
    # - running (future use)
    status: Mapped[str] = mapped_column(
        String(50),
        nullable=False
    )

    ############################################
    # Timestamps
    ############################################
    # When ingestion started
    started_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False
    )

    # When ingestion finished
    # Nullable if run failed or still running
    finished_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=True
    )

    ############################################
    # Metrics
    ############################################
    # Number of records fetched from external API
    records_fetched: Mapped[int] = mapped_column(
        Integer,
        nullable=True
    )

    ############################################
    # Error tracking
    ############################################
    # Error message if ingestion failed
    error_message: Mapped[str] = mapped_column(
        String(500),
        nullable=True
    )

    ############################################
    # City-level results
    ############################################
    # JSON string storing city-level weather data
    # for the latest ingestion run.
    # This is a simple way to store structured data
    # without needing a separate table or complex schema.
    city_results: Mapped[list] = mapped_column(
        JSON,
        nullable=True
    )

