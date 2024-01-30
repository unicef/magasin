from click_aliases import ClickAliasedGroup
from mag.mag_core import options, launch_ui
from mag.mag import cli

COMPONENT='dagster'

@cli.group("dagster", cls=ClickAliasedGroup, aliases=["d"])
def dagster():
  """Dagster commands"""


@dagster.command(aliases=['user-interface'])
@options.realm
@options.ports(default='3000:80')
def ui (realm, ports):
  """Launch dagster UI"""
  launch_ui(realm=realm, component=COMPONENT,service_name='service/dagster-dagster-webserver', ports=ports)

 