from datetime import datetime

from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import Integer, String, DateTime


# Base class for all database models
# SQLAlchemy uses this metadata to create tables
class Base(DeclarativeBase):
    pass


# Represents a single ingestion run of the external data integration service
class IngestionRun(Base):
    __tablename__ = "ingestion_runs"

    # Primary key
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # Name of data source (weather API, traffic API, etc.)
    source_name: Mapped[str] = mapped_column(String(100), nullable=False)

    # Run status: success / failed / running
    status: Mapped[str] = mapped_column(String(50), nullable=False)

    # When ingestion started
    started_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)

    # When ingestion finished (nullable if failed or still running)
    finished_at: Mapped[datetime] = mapped_column(DateTime, nullable=True)

    # Number of records fetched from external API
    records_fetched: Mapped[int] = mapped_column(Integer, nullable=True)

    # Error message if ingestion failed
    error_message: Mapped[str] = mapped_column(String(500), nullable=True)