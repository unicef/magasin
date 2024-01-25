


def split_realm(realm: str) -> tuple:
    """
    Split the realm into prefix and suffix based on the last occurrence of "-".

    Args:
    - realm (str): The input realm string.

    Returns:
    - tuple: A tuple containing prefix and suffix.
    """
    last_dash_index = realm.rfind("-")

    if last_dash_index == -1:
        prefix = realm
        suffix = ""
    else:
        prefix = realm[:last_dash_index]
        suffix = realm[last_dash_index + 1:]

    return prefix, suffix



def get_namespace(component_name: str, realm='magasin') -> str:
    prefix, suffix = split_realm(realm)
    namespace = ""
    if prefix:
        namespace = prefix + '-' + component_name
    if suffix:
        namespace = namespace + "-" + suffix
    return namespace

