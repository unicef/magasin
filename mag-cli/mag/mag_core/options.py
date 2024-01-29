"""
Reusable command line options
"""
import click
from .validators import validate_realm

def validate_realm_callback(ctx, param, value):
  """Validates if the realm has a correct value
     See: https://click.palletsprojects.com/en/8.1.x/options/#callbacks-for-validation
  Raises:
      click.BadParameter: If name is not valid
  """
  if not validate_realm(value):
      raise click.BadParameter("Realm can only contain letters, numbers and '-'")
  return value


# TODO
def validate_port_callback(ctx, param, value):
   return value


# 
# Shared Definition of realm option
#
realm = click.option('-r', '--realm', default="magasin", 
                     show_default=True, 
                     help='magasin realm', 
                     callback=validate_realm_callback)


def ports(default: str):
  return click.option('-p', '--ports', 
                     default=default,
                     show_default=True, 
                     help='Redirection ports. Format <localhost_port>:<pod_port>. Example: 8080:8080', 
                     callback=validate_port_callback)