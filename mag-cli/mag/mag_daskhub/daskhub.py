import click
from mag.mag_core import options, get_namespace, launch_ui

COMPONENT='daskhub'

@click.group
@options.realm
def daskhub(realm):
  """daskhub commands"""
  namespace = get_namespace(component_name=COMPONENT, realm=realm)
  click.echo("namespace: " + namespace)

@click.command
@options.realm
@click.option("-p",'--port', default="80",show_default=True, help="daskhub proxy-public service port")
def ui(realm, port):
  """Launch jupyterhub user interface"""
  click.launch(f"http://localhost:{port}")


daskhub.add_command(ui)