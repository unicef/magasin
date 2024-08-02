"""
Reusable command line options

These are options that can be included in a command and that can be
reused in multiple commands

Example: 

Add the --realm <realm> option. The realm is validated against the 
allowed format returns errors when is not.

```python
from mag.mag_core import options

@cli.group('drill', cls=ClickAliasedGroup, aliases=['dr'])
@options.realm
def drill(realm):
    printf(realm)
"""


import click
from .validators import validate_realm, validate_ports

def validate_realm_callback(ctx, param, value):
    """Validates if the realm has a correct value
    
    See: https://click.palletsprojects.com/en/8.1.x/options/#callbacks-for-validation
    
    Raises:
        click.BadParameter: If name is not valid
    """
    if not validate_realm(value):
        raise click.BadParameter("Realm can only contain letters, numbers and '-'")
    return value


def validate_port_callback(ctx, param, value):
    """Click callback to validate the port format
    It validates the ports using `mag_core.validators.validate_ports`
        
    Raises:
        click.BadParameter: If port format is not valid
    """
    if not validate_ports(value):
        raise click.BadParameter("The format of the ports is number:number. Where number is between 1 and 65535. Example: 80:80")
    return value


# 
# Shared Definition of realm option
#
realm = click.option('-r', '--realm', default="magasin", 
                     show_default=True, 
                     help='magasin realm', 
                     callback=validate_realm_callback)
"""
Adds the --realm option. 
"""


def ports(default: str):
    """
    Adds the --ports option.

    Validates the port format.

    Parameters:
        default (str): The default value for the option.

    Returns:
        click.Option: The click option object.

    """
    return click.option('-p', '--ports', 
                        default=default,
                        show_default=True, 
                        help='Redirection ports. Format <localhost_port>:<pod_port>. Example: 8080:8080', 
                        callback=validate_port_callback)