"""
DPGA Pipeline Definitions
"""
import os

from dagster import Definitions, ScheduleDefinition, load_assets_from_modules, define_asset_job, EnvVar

from . import assets

from .resources import DPGResource, MinioJSONIOManager, MinioJSONParquetIOManager, MinioResource

# Load all assets
all_assets = load_assets_from_modules([assets], group_name="DPG_assets")

# Create an asset job that materializes all assets of the pipeline
all_assets_job = define_asset_job(name="all_assets_job",
                                  selection=all_assets,
                                  description="Gets a copy of all the DPG Assets")


# Setup the resource based on the environment
deployment_name = os.getenv("DAGSTER_DEPLOYMENT", "local")

if deployment_name == 'local':
    # Uses localhost:9000
    # You should launch mag minio api 
    minio_resource = MinioResource()
    
    # Cron schedule
    # See https://en.wikipedia.org/wiki/Cron
    # For testing we set a schedule to get all the assets every minute 
    main_schedule = ScheduleDefinition(job=all_assets_job,
                                   cron_schedule="* * * * *"
                                   )

else:
    minio_resource = MinioResource(
        endpoint=EnvVar('MINIO_ENDPOINT'),
        access_key=EnvVar('MINIO_ACCESS_KEY'),
        secret_key=EnvVar("MINIO_SECRET_KEY"),
        secure=EnvVar("MINIO_SECURE"),
        cert_check=EnvVar("MINIO_CERT_CHECK")
    )
    # For production we set a schedule to get all the assets every day at 0:00
    # See # https://en.wikipedia.org/wiki/Cron 
    main_schedule = ScheduleDefinition(job=all_assets_job,
                                   cron_schedule="0 0 * * *"
                                   )


resources = {
    "dpg_api": DPGResource(),
    "minio_json_io_manager": MinioJSONIOManager(minio_resource=minio_resource, root_path="/data/" ),
    "minio_json_parquet_io_manager": MinioJSONParquetIOManager(minio_resource=minio_resource, root_path="/data/")
}


defs = Definitions(
    assets=all_assets,
    jobs=[all_assets_job],
    schedules=[main_schedule],
    resources=resources
)
