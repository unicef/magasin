from dagster import Definitions, load_assets_from_modules, define_asset_job, ScheduleDefinition

from . import assets

all_assets = load_assets_from_modules([assets])

# Create an asset job that materializes all assets of the pipeline
all_assets_job = define_asset_job(name="all_assets_job",
                                  selection=all_assets,
                                  description="Gets all the DPG assets")

main_schedule = ScheduleDefinition(job=all_assets_job,
                                   cron_schedule="* * * * *"
                                   )


defs = Definitions(
    assets=all_assets,
    jobs=[all_assets_job],
    schedules=[main_schedule]
)
