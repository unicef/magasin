"""
This module contains functions for validating different inputs 
in a magasin application.
"""



import re


def validate_realm(realm: str) -> bool:
    """
    Verify if the realm contains only letters, numbers, "-", and "_".

    Args:
    - realm (str): The input realm string.

    Returns:
    - bool: True if the realm contains only valid characters, False otherwise.
    """
    # Define a regular expression pattern for valid characters
    pattern = re.compile(r'^[a-z0-9-]+$')

    # Use re.match to check if the entire string matches the pattern
    return bool(pattern.match(realm))


def validate_ports(ports: str) -> bool:
    """
    Validate that the ports in the input string are numbers between 1 and 65535.

    Args:
    - ports (str): Input string with the format "number:number".

    Returns:
    - bool: True if the ports are valid, False otherwise.
    """
    try:
        localhost, pod_port = map(int, ports.split(':'))
        return 1 <= localhost <= 65535 and 1 <= pod_port <= 65535
    except ValueError:
        return False
    

def validate_pod_name(name: str) -> bool:
    """
    Validates if a Kubernetes pod name is valid according to Kubernetes naming conventions.

    Parameters:
    - name (str): The pod name to validate.

    Returns:
    - bool: True if the pod name is valid, False otherwise.
    """
    if not name:
        return False

    # Pod name must be no more than 253 characters in length
    if len(name) > 253:
        return False

    # Pod name must consist of lower case alphanumeric characters, '-' or '.', and
    # must start and end with an alphanumeric character
    pattern = re.compile(r'^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$')
    return bool(pattern.match(name))
    