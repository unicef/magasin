"""
This module contains functions related to magasin realms.

Magasin realms are used to generate namespaces based on component names and realms.
The functions in this module allow splitting a realm into prefix and suffix based on the last occurrence of "-",
and generating a namespace based on the component name and realm.

For more information about magasin realms, please see the [magasin realms documentation](https://unicef.github.io/magasin/install/advanced.html#magasin-realms).
"""

def split_realm(realm: str) -> tuple:
    """
    Split the realm into prefix and suffix based on the last occurrence of "-".

    Args:
        realm (str): The input realm string.

    Returns:
        tuple: A tuple containing prefix and suffix.

    Example:
        * split_realm("magasin") -> ("magasin", "")
        * split_realm("magasin-post") -> ("magasin", "post")
        * split_realm("magasin-1-post") -> ("magasin-1", "post")
        * split_realm("dev-magasin-1") -> ("dev-magasin", "1")

    Reference:
        For more information about magasin realms, please see the [magasin realms documentation](https://unicef.github.io/magasin/install/advanced.html#magasin-realms).
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
    """
    Generate a namespace based on the component name and realm.


    Args:
        component_name (str): The magasin component name (superset, daskhub, drill, ...)
        realm (str, optional): The realm. Defaults to 'magasin'.

    Example:
        * `get_namespace("superset", "magasin")` -> "magasin-superset"
        * `get_namespace("superset", "magasin-postfix")` -> "magasin-superset-postfix"

    Reference:
        For more information about magasin realms, please see the [magasin realms documentation](https://unicef.github.io/magasin/install/advanced.html#magasin-realms).
    """
    prefix, suffix = split_realm(realm)
    namespace = ""
    if prefix:
        namespace = prefix + '-' + component_name
    if suffix:
        namespace = namespace + "-" + suffix
    return namespace

