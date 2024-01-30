import click
from click_aliases import ClickAliasedGroup
from mag.mag import cli
from mag.mag_core import options, get_namespace, launch_ui

COMPONENT='superset'

@cli.group('superset', cls=ClickAliasedGroup, aliases=['ss'])
@options.realm
def superset(realm):
  """Apache Superset commands"""
  namespace = get_namespace(component_name=COMPONENT, realm=realm)
  click.echo("namespace: " + namespace)

@click.command
@options.realm
@options.ports(default="8088:8088")
def ui(realm, ports):
  """Launch Superset user interface"""
  launch_ui(realm, component=COMPONENT, service_name=f"service/superset", ports=ports)


superset.add_command(ui)