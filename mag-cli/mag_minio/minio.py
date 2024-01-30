import click
from click_aliases import ClickAliasedGroup
import subprocess
import signal


from mag.mag import cli
from mag.mag_core import options, launch_ui, forward_port, generate_random_string, std_aliases


from . import minio_options
from . import mc

COMPONENT='tenant'


def launch_hl(realm:str, tenant:str, ports:str, wait=False) -> None:
  forward_port(realm=realm, component=COMPONENT, service_name=f'svc/{tenant}-hl', ports=ports)
  if wait:
    try:
      # Wait for user to press Ctrl+C
        signal.pause()
    except KeyboardInterrupt:
          # Handle Ctrl+C: terminate the server and clean up
          #process.terminate()
          #os.waitpid(process.pid, 0)
          click.echo("\nServer terminated. Exiting.")



#----------
# minio
#----------
@cli.group('minio', cls=ClickAliasedGroup, aliases=["m"])
@options.realm
@minio_options.tenant()
def minio(realm, tenant):
  """MinIO commands"""
  #namespace = get_namespace(component_name=COMPONENT, realm=realm)
  #click.echo("namespace: " + namespace)



#----------
# minio   sui
#----------
@minio.command
@options.realm
@options.ports(default="9443:9443")
@minio_options.tenant()
def sui(realm, tenant, ports):
  """Launch user tenant ssl secured user interface"""
  launch_ui(realm, component=COMPONENT, service_name=f"svc/{tenant}-console", ports=ports, protocol="https")


#----------
# minio ui
#----------
@minio.command
@options.realm
@options.ports(default="9090:9090")
@minio_options.tenant()
def ui(realm, tenant, ports):
  """Launch user tenant non-ssl user interface"""
  launch_ui(realm, component=COMPONENT, service_name=f"svc/{tenant}-console", ports=ports, protocol="http")


#----------
# minio add
#----------
@minio.group('add', cls=ClickAliasedGroup, aliases=std_aliases.add)
def add():
  pass

#----------
# minio api
#----------
@minio.command
@options.realm
@options.ports(default="9000:9000")
@minio_options.tenant()
def api(realm, tenant, ports):
  """Launch minio server API. Launch this to be able to use mc command."""
  click.echo("")
  launch_hl(realm=realm, tenant=tenant, ports=ports, wait=True)
  

#----------
# minio add bucket 
#----------
@add.command(aliases=["b"])
@options.realm
@options.ports(default="9000:9000")
@minio_options.tenant()
@click.option("-b", "--bucket-name", help="Bucket name", default="")
def bucket(realm, tenant, ports, bucket_name):
  """Create a minio bucket in the tenant"""
  click.echo("Create Bucket")  

  # TODO use https://min.io/docs/minio/linux/developers/python/minio-py.html
  # May need Minio(..., cert_check=False)
  launch_hl(realm=realm, tenant=tenant, ports=ports)
  from time import sleep 
  sleep(1)
  # Check if the tenant alias is set
  if not mc.check_mc_admin_info(tenant):
    # TODO This needs to be removed if bucket is created with python library
    click.echo(f"minio tenant configuration alias '{tenant}' not set. Try running:", err=True)
    click.echo(f"      mag minio api; mc alias set {tenant} https://localhost:9000 <accesskey/user> <secretkey/password> --insecure")
    exit(-1)
  else: 
    click.echo("tenant alias setup")
  if bucket_name == "":
      bucket_name = "magasin-" + generate_random_string(5)
  try:
    mc_command = f"mc mb {tenant}/{bucket_name} --insecure"
    click.echo("mc command:" + mc_command)    
    subprocess.run(mc_command, shell=True)
  except Exception as e:
    print('exception', e)

#----------
#    minio add user
#----------
@add.command(aliases=["u"])
@options.realm
@options.ports(default="9000:9000")
@minio_options.tenant()
@click.option("-a", "--accesskey", help="user name", default="")
@click.option("-s", "--secretkey", help="password", default="")
def user(realm, tenant, ports, accesskey, secretkey):
  """Create a minio user in the tenant"""

  # TODO use https://min.io/docs/minio/linux/developers/python/minio-py.html
  # May need Minio(..., cert_check=False)
  launch_hl(realm=realm, tenant=tenant, ports=ports)
  from time import sleep 
  sleep(1)
  # Check if the tenant alias is set
  if not mc.check_mc_admin_info(tenant):
    # TODO This needs to be removed if bucket is created with python library
    click.echo(f"minio tenant configuration alias '{tenant}' not set. Try running:", err=True)
    click.echo(f"      mag minio api; mc alias set {tenant} https://localhost:9000 <accesskey/user> <secretkey/password> --insecure")
    exit(-1)
  else: 
     click.echo(f"minio tenant ok")

  if accesskey == "":
      accesskey = "magasin-" + generate_random_string(5)
  if secretkey == "":
      secretkey = generate_random_string(32)
  try:
    mc_command = f"mc admin user add {tenant} {accesskey} {secretkey} --insecure"
    click.echo("mc command:" + mc_command)    
    subprocess.run(mc_command, shell=True)
    click.echo("")
    click.echo(f"Created\n    user/accesskey: {accesskey}\n    password/secretkey: {secretkey}")
    click.echo(f"\nNote: you still need to assign permissions/policies to the user. You can do it with the UI: `mag minio ui`")
    click.echo("")
  except Exception as e:
    print('exception', e)



# Minio Sub Commands
minio.add_command(ui)
minio.add_command(sui)
minio.add_command(api)
minio.add_command(add)

# Add subcommands
add.add_command(bucket)
add.add_command(user)