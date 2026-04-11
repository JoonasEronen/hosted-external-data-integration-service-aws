from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.templating import Jinja2Templates

from app.database.connection import create_tables
from app.database.repository import get_latest_ingestion_runs
from app.scheduler import create_scheduler


############################################
# Application lifecycle
############################################
# FastAPI lifespan hook used for:
# - creating database tables at startup
# - starting the background ingestion scheduler
# - shutting down the scheduler gracefully on service stop
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create database tables when the service starts.
    # This is acceptable for MVP/demo purposes.
    create_tables()
    print("Database tables created")

    # Create and start the background scheduler.
    scheduler = create_scheduler()
    scheduler.start()
    print("Scheduler started")

    try:
        yield
    finally:
        # Shut down the scheduler cleanly when the app stops.
        scheduler.shutdown()
        print("Scheduler stopped")


############################################
# FastAPI application
############################################
# Main application instance for the hosted integration service.
app = FastAPI(lifespan=lifespan)


############################################
# Templates
############################################
# Jinja2 templates used for server-rendered dashboard views.
templates = Jinja2Templates(directory="app/templates")


############################################
# API endpoints
############################################
# Basic service root endpoint.
# Useful as a simple confirmation that the app is running.
@app.get("/")
def root():
    return {"service": "hosted-external-data-integration-service-aws"}


############################################
# Health endpoint
############################################
# Health check endpoint used by:
# - Application Load Balancer health checks
# - service monitoring
# - quick operational verification
@app.get("/health")
def health():
    return {"status": "ok"}


############################################
# Dashboard endpoint
############################################
# Server-rendered operational dashboard showing:
# - recent ingestion runs
# - service status
# - latest ingestion metadata
@app.get("/dashboard")
def dashboard(request: Request):
    # Fetch latest ingestion history from PostgreSQL.
    ingestion_runs = get_latest_ingestion_runs(limit=10)
    latest_run = ingestion_runs[0] if ingestion_runs else None
   

    # Render the dashboard template with service and ingestion data.
    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "title": "Hosted External Data Integration Service",
            "description": (
                "This dashboard shows recent ingestion runs from the hosted "
                "external data integration service. The service periodically "
                "fetches weather data from an external API and tracks ingestion "
                "metadata in PostgreSQL."
            ),
            "status": "Running",
            "source_name": "Open-Meteo API",
            "latest_run": latest_run,
            "run_count": len(ingestion_runs),
            "ingestion_runs": ingestion_runs,
            "city_results": latest_run.city_results
        },
    )