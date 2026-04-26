import logging

from apscheduler.schedulers.background import BackgroundScheduler

from app.services.external_api import run_ingestion_job

logger = logging.getLogger(__name__)

############################################
# Background scheduler
############################################
# Scheduler used to simulate a continuously running
# hosted integration service.
def create_scheduler():
    scheduler = BackgroundScheduler()
    
    logger.info("Creating background scheduler")

    # Run ingestion job every 60 seconds.
    # The interval is intentionally short for demo visibility.
    scheduler.add_job(
        run_ingestion_job,
        "interval",
        seconds=60,
        id="weather_ingestion_job",
        replace_existing=True,
    )
    
    logger.info("Background scheduler configured job_id=weather_ingestion_job interval_seconds=60")
    
    return scheduler