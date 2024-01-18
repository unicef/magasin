

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
    
def split_ports(ports: str) -> tuple:
    """
    Split the input string with the format "number:number" into localhost and pod port.

    Args:
    - ports (str): Input string with the format "number:number".

    Returns:
    - tuple: A tuple containing localhost and pod port.

    Raises:
    - ValueError: If the input string is not in the expected format or if ports are not valid.
    """
    if not validate_ports(ports):
        raise ValueError("Invalid ports. Port numbers should be between 1 and 65535.")

    try:
        localhost, pod_port = map(int, ports.split(':'))
        return localhost, pod_port
    except ValueError:
        raise ValueError("Invalid ports format. Expected format: 'number:number'")