import click
from click_aliases import ClickAliasedGroup
from mag.mag import cli
from mag.mag_core import options, get_namespace, launch_ui

COMPONENT='daskhub'

@cli.group('daskhub', cls=ClickAliasedGroup, aliases=['dh'])
@options.realm
def daskhub(realm):
  """Daskhub/Jupyterhub commands"""
  namespace = get_namespace(component_name=COMPONENT, realm=realm)
  click.echo("namespace: " + namespace)

@daskhub.command()
@options.realm
@options.ports(default="8001:80")
def ui(realm, ports):
  """Launch jupyterhub user interface"""
  launch_ui(realm=realm,component=COMPONENT, service_name='service/proxy-public', ports=ports)

