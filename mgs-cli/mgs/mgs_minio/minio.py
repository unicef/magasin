import click
from mgs.mgs_core import options, get_namespace, launch_ui

COMPONENT='tenant'

def validate_tenant_callback(ctx, param, value):
  
  return value

tenant_option = click.option('-t', '--tenant', default="myminio", 
                     show_default=True, 
                     help='minio tenant name', 
                     callback=validate_tenant_callback)
@click.group
@options.realm
@tenant_option
def minio(realm,tenant):
  """minio commands"""

  namespace = get_namespace(component_name=COMPONENT, realm=realm)
  click.echo("namespace: " + namespace)

@click.command
@options.realm
@options.ports(default="9443:9443")
@tenant_option
def ui(realm,tenant, ports):
  """Launch user tenant user interface"""
  launch_ui(realm, component=COMPONENT, service_name=f"svc/{tenant}-console", ports=ports, protocol="https")


minio.add_command(ui)