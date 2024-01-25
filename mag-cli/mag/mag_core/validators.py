import re

""" Validate if a value is within the allowed conditions"""

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