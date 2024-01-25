import random
import string

def generate_random_string(length=7):
    """
    Generate a random alphanumeric lowercase string of a specified length.

    Parameters:
    - length (int): The desired length of the random string.

    Returns:
    - str: A random string containing letters (both lowercase and uppercase) and digits.
    """
    characters = string.ascii_lowercase + string.digits
    return ''.join(random.choice(characters) for _ in range(length))
