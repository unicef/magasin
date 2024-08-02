
"""
This module provides functions for launching and managing services in a 
Kubernetes cluster.

It includes functions for generating port forwarding commands, checking 
if a TCP port is open, forwarding ports, launching user interfaces, and 
executing commands in Kubernetes pods.
"""

import subprocess
import signal
import socket
import time
import os
import time
import atexit
from typing import List

import click

from .realm import get_namespace
from .ports import split_ports

# Rest of the code...
import subprocess
import signal
import socket
import time
import os
import time
import atexit
from typing import List

import click

from .realm import get_namespace
from .ports import split_ports


def port_forward_command_arr(realm: str, component: str, service_name: str, ports: str, verbose=False) -> List:
    """Generate a command array for port forwarding.

    This function generates a command array for port forwarding using `kubectl` command.

    Args:
        realm (str): The magasin realm.
        component (str): The component of the command (f.i superset, daskhub, drill,...).
        service_name (str): The Kubernetes service name to forward.
        ports (str): The ports to forward. Follows the format "local_port:remote_port".
        verbose (bool, optional): Whether to include verbose output. Defaults to False.

    Returns:
        List: The generated command array.
    """
    namespace = get_namespace(component, realm)
    port_forward_command_arr = [
        "kubectl", "port-forward", "--address=0.0.0.0", "--namespace", namespace, service_name, ports]
    if verbose:
        click.echo("port_forward_command_arr: " +
                   " ".join(port_forward_command_arr))
    return port_forward_command_arr


def port_forward_command_str(realm: str, component: str, service_name: str, ports: str, verbose=False) -> str:
    """
    Returns a string representation of the port forward command.

    Args:
        realm (str): The magasin realm.
        component (str): The component of the command (f.i superset, daskhub, drill,...).
        service_name (str): The Kubernetes service name to forward.
        ports (str): The ports to forward. Follows the format "local_port:remote_port".
        verbose (bool, optional): Whether to include verbose output. Defaults to False.

    Returns:
        str: The port forward command as a string.

    Example:
    ```
    port_forward_command_str("magasin", "superset", "superset", "8088:8088")
    ```

    """
    return " ".join(port_forward_command_arr(realm=realm, component=component, service_name=service_name, ports=ports, verbose=verbose))


def terminate_process(process):
    """
    Terminate the given process if it is running.

    Parameters:
    - process: A subprocess.Popen object representing the process to be terminated.

    Usage:
    terminate_process(process)

     Notes:
     - If the process is not running or is already terminated, this function returns without taking any action.
     - It checks if the process is running (poll() is None) and terminates it using terminate().
       It then waits for the process to finish using wait().
     """
    
    if not process:
        return
    if process.poll() is None:
        process.terminate()
        process.wait()


def is_port_open(host, port, timeout=15):
    """
    Check if a TCP port is open and responding.

    Args:
        host (str): A string representing the host to check. Example: localhost
        port (int): An integer representing the port to check. Example: 8080
        timeout (int): An integer representing the timeout in seconds. Default is 15 seconds.

    Returns:
        bool: Indicates whether the port is open and responding.

    """
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            with socket.create_connection((host, port), timeout=1) as _:
                return True
        except (socket.timeout, ConnectionRefusedError):
            time.sleep(1)  # Wait for 1 second before retrying
        except OSError:
            return False
    return False


def forward_port(realm: str, component: str, service_name: str, ports: str, verbose=False) -> None:
    """
    Forward ports for the specified realm, component, and service name.

    Args:
        realm (str): A string representing the realm.
        component (str): A string representing the component.
        service_name: (str) A string representing the service name. The service name can be obtained using kubectl get services --namespace magasin-superset).
        ports (str): A string representing the ports to be forwarded (example: "8000:8000").
        verbose (bool): A boolean indicating whether to enable verbose mode (default is False).

    Returns:
    None

    Usage:

    forward_port(realm, component, service_name, ports, verbose)

    Example:
    ```
    # Given this
    kubectl get service -n magasin-superset
    NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
    superset                  ClusterIP   10.100.96.47     <none>        8088/TCP   7d22h
    ```
    You can forward this service
    ```
    forward_port("magasin", "superset", "superset", "8088:8088")
    ```

    Notes:
    
    - Assumes the port_forward_command function is defined elsewhere in the code.
    - Uses subprocess.Popen to launch the port forwarding command in a subprocess.
    - Registers the terminate_process function using atexit.register, ensuring that the port forwarding process
      is terminated when the script exits.
    """
    port_forward_command = port_forward_command_arr(
        realm, component, service_name, ports, verbose)
    click.echo("forward_port command: " + " ".join(port_forward_command))
    process = subprocess.Popen(port_forward_command, shell=False)

    local, _ = split_ports(ports)
    click.echo("Waiting for port to be open...")
    if not is_port_open(host='localhost', port=local):
        click.echo("Port could not be opened.")
        exit(-1)
    click.echo("Port ready.")

    atexit.register(terminate_process, process)


def launch_ui(realm: str, component: str, service_name: str, ports: str, protocol: str = "http", verbose=False) -> None:
    """
    Launches the user interface for a given realm, component, and service.

    Args:
        realm (str): The realm of the magasin instance.
        component (str): The magasin component (f.i superset, daskhub, drill, ...)
        service_name (str): The name of the kubernetes service to forward.
        ports (str): The ports to forward, using the format "local_port:remote_port".
        protocol (str, optional): The protocol to use (default is "http").
        verbose (bool, optional): Whether to display verbose output (default is False).

    Returns:
        None: Nothing
    """    
    forward_port(realm=realm, component=component,
                 service_name=service_name, ports=ports, verbose=verbose)

    localhost_port, _ = split_ports(ports)
    url = f"{protocol}://localhost:{localhost_port}"
    click.echo(f"Open browser at: {url}")
    click.launch(url)
    click.echo("launch ui")

    try:
        # Wait for user to press Ctrl+C
        signal.pause()
    except KeyboardInterrupt:
        # Handle Ctrl+C: terminate the server and clean up
        process.terminate()
        os.waitpid(process.pid, 0)
        click.echo("\nServer terminated. Exiting.")


def launch_command(realm: str, component: str, pod_name: str, command: str = '/bin/bash'):
    """
    Launches a command in a Kubernetes pod.

    Args:
        realm (str): The magasin realm (e.g., magasin).
        component (str): The name of the magasin component.
        pod_name (str): The name of the pod.
        command (str, optional): The command to be executed in the pod. Defaults to '/bin/bash'.

    Returns:
        None

    Raises:
        None

    Example:
        >>> launch_command('magasin', 'component_name', 'pod-1', 'ls -l')
        Running: kubectl exec pod-1 --namespace magasin -ti -- ls -l
        <output of the command>

    Note:
        This function uses the `kubectl` command-line tool to execute a command in a Kubernetes pod.
        Make sure you have `kubectl` installed and configured properly before using this function.
    """
    namespace = get_namespace(component_name=component, realm=realm)
    user_root = ''

    command = f"kubectl exec {pod_name} --namespace {namespace} -ti -- {command}"
    click.echo(f"Running: {command}")
    subprocess.run(command, shell=True)
