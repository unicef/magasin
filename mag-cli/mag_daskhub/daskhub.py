import click
from click_aliases import ClickAliasedGroup
from mag.mag import cli
from mag.mag_core import options, get_namespace

COMPONENT='daskhub'

@cli.group('daskhub', cls=ClickAliasedGroup, aliases=['dh'])
@options.realm
def daskhub(realm):
  """Daskhub/Jupyterhub commands"""
  namespace = get_namespace(component_name=COMPONENT, realm=realm)
  click.echo("namespace: " + namespace)

@daskhub.command()
@options.realm
@click.option("-p",'--port', default="80",show_default=True, help="daskhub proxy-public service port")
def ui(realm, port):
  """Launch jupyterhub user interface"""
  click.launch(f"http://localhost:{port}")

