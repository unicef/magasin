
"""
This module serves as the main entrance for the magasin CLI.

It defines the CLI commands and options using the Click library. The CLI provides a way to interact with various magasin components and perform common tasks.

To execute the CLI, run this module as the main script.

Example:
    python mag.py [command] [options]

"""

import click
from click_aliases import ClickAliasedGroup
import mag.version as version


def print_version(ctx, param, value):
    """
    Print the version of the magasin CLI.

    This function is a callback for a Click command option. It prints the version of the magasin CLI using the `version.get_version()` function and exits the program.

    Args:
        ctx (click.Context): The Click context object.
        param (click.Parameter): The Click parameter object.
        value (Any): the version value.

    Returns:
        None
    """
    if not value or ctx.resilient_parsing:
        return
    click.echo(f'magasin CLI v{version.get_version()}')
    ctx.exit()


@click.group(cls=ClickAliasedGroup)
@click.option('-v', '--verbose', count=True)
@click.option('--version', is_flag=True, callback=print_version,
              expose_value=False, is_eager=True)
@click.pass_context
def cli(ctx, verbose):
    """magasin client is the glue between magasin components, it makes easier common tasks"""
    ctx.ensure_object(dict)


# TODO add this as dynamically
    
from mag_dagster import dagster
cli.add_command(dagster)

from mag_minio import minio
cli.add_command(minio)

from mag_superset import superset
cli.add_command(superset)

from mag_daskhub import daskhub
cli.add_command(daskhub)

from mag_drill import drill
cli.add_command(drill)

if __name__ == "__main__":
    cli()