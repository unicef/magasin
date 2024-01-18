import click
from mgs.mgs_core import options, get_namespace, launch_ui

COMPONENT='superset'

@click.group
@options.realm
def superset(realm):
  """superset commands"""
  namespace = get_namespace(component_name=COMPONENT, realm=realm)
  click.echo("namespace: " + namespace)

@click.command
@options.realm
@options.ports(default="8088:8088")
def ui(realm, ports):
  """Launch superset user interface"""
  launch_ui(realm, component=COMPONENT, service_name=f"service/superset", ports=ports)


superset.add_command(ui)