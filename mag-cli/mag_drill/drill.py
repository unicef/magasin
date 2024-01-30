import click
from click_aliases import ClickAliasedGroup
from mag.mag import cli
from mag.mag_core import options, launch_command, launch_ui, std_aliases


COMPONENT='drill'

#----------
# drill
#----------
@cli.group('drill', cls=ClickAliasedGroup, aliases=['dr'])
@options.realm
def drill(realm):
  """Apache Drill commands"""
  #namespace = get_namespace(component_name=COMPONENT, realm=realm)
  #click.echo("namespace: " + namespace)



#----------
# drill ui
#----------
@click.command
@options.realm
@options.ports(default="8047:8047")
def ui(realm, ports):
  """Launch Drill user interface"""
  launch_ui(realm, component=COMPONENT, service_name=f"service/drill-service", ports=ports, protocol="http")


from mag.mag_core import validate_pod_name
def validate_pod_name_callback(ctx, param, value):
  """Validates if the pod_name argument has a valid value
     See: https://click.palletsprojects.com/en/8.1.x/options/#callbacks-for-validation
  Raises:
      click.BadParameter: If does 
  """
  if not validate_pod_name(value):
      raise click.BadParameter("Podname can only contain letters, numbers, '-' and '.'. Must start and end with an alphanumeric character.")
  return value

#----------
# drill shell
#----------
@drill.command(aliases=std_aliases.shell)
@options.realm
@click.option('-n', '--pod-name', help='name of the pod to open the shell', default='drillbit-0', show_default=True, callback=validate_pod_name_callback)
def shell(realm, pod_name):
  """Launch a shell"""
  launch_command(realm=realm, component=COMPONENT, pod_name=pod_name )



#----------
# drill add
#----------
@drill.group('add', cls=ClickAliasedGroup, aliases=std_aliases.add)
def add():
  """Add items to Drill"""

#----------
# drill add store
#----------
@add.command
@options.realm
@options.ports(default="8047:8047")
@click.option('-e', '--endpoint', help='MinIO API Endpoint', default='')
@click.option('-b', '--bucket', help='Bucket')
@click.option('-a', '--access-key', help='Access key / username')
@click.option('-s', '--secret-key', help='Secret key / password')
def store(realm, endpoint, bucket, access_key, secret_key, ports):
  """Add MinIO/s3 store """
  click.echo("Add Minio Store")
  if (endpoint == ""):
    # Use the standard for the realm 
    print("hola")
