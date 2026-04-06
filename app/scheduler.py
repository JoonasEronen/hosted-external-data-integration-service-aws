from apscheduler.schedulers.background import BackgroundScheduler

from app.services.external_api import run_ingestion_job


############################################
# Background scheduler
############################################
# Scheduler used to simulate a continuously running
# hosted integration service.
def create_scheduler():
    scheduler = BackgroundScheduler()

    # Run ingestion job every 60 seconds.
    # The interval is intentionally short for demo visibility.
    scheduler.add_job(run_ingestion_job, "interval", seconds=60)

    return scheduler