import subprocess
from typing import List

import click

from .realm import get_namespace
from .ports import split_ports

def port_forward_command(realm:str, component: str, service_name:str, ports:str, verbose=False) -> List:
    namespace = get_namespace(component, realm)
    port_forward_command_arr = ["kubectl", "port-forward",  "--namespace", namespace, service_name, ports]
    if verbose:
      click.echo("Launch_ui command:" + port_forward_command_arr.join())
    return port_forward_command_arr

def launch_ui(realm:str, component: str, service_name:str, ports:str, protocol: str = "http", verbose=False)-> None:
    port_forward_command_arr = port_forward_command(realm=realm, 
                                component=component, 
                                service_name=service_name,
                                ports=ports, 
                                verbose=verbose)
    
    subprocess.Popen(port_forward_command_arr, shell=False)

    localhost_port, _ = split_ports(ports)
    url = f"{protocol}://localhost:{localhost_port}"
    click.echo(f"Open browser at: {url}")
    click.launch(url)
    click.echo("launch ui")