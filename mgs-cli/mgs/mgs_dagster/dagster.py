import click
from mgs.mgs_core import options, get_namespace

@click.command
@options.realm
def dagster(realm):
  """dagster commands"""
  component = 'dagster'

  get_namespace(component_name=component, realm=realm)


  
  