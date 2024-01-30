import click
from mag.mag_core import options, get_namespace, launch_ui

COMPONENT='dagster'

@click.group
@options.realm
def dagster(realm):
  """dagster commands"""
  component = 'dagster'

  get_namespace(component_name=component, realm=realm)


@click.command
@options.realm
def ui (realm):
  """Launch dagster UI"""
  
  

  