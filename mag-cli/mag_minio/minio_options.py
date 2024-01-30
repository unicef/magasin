import click

def validate_tenant_callback(ctx, param, value) -> str:  
  return value


def tenant():
  """-t, --tenant"""
  return click.option('-t', '--tenant', default="myminio", 
                     show_default=True, 
                     help='minio tenant name', 
                     callback=validate_tenant_callback)
