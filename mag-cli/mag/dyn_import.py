import importlib
import pkgutil

##
## TODO - Not yet functional.
##
## The idea behind this is to allow to dynamically import a list of modules that are specified in a configuration file.
## This would allow third parties to create their own modules and add them to the CLI without having to modify the main code.
## For example let's say airflow gets integrated with magasin, then the airflow team could create a module that would be
## developed



def import_mag_modules():
    """
    Dynamically import all modules in the current environment with names starting with "mag.mag_",
    and run click.command(method) for each method in those modules.

    Returns:
    - dict: A dictionary where keys are module names and values are the imported module objects.
    """
    mag_modules = {}

    for module_info in pkgutil.iter_modules():
        print(module_info)
        if module_info.name.startswith("mag.mag_"):
            module_name = module_info.name
            try:
                module = importlib.import_module(module_name)
                mag_modules[module_name] = module

                # Extract the method name (what is after "mag_")
                method_name = module_name.split(".")[-1][4:]

                # Assuming the method is a function in the module
                method = getattr(module, method_name, None)

                if method and callable(method):
                    # Run click.command(method)
                    command = click.command()(method)
                    # You can execute the command here or store it for later use
                    # command()

            except ImportError as e:
                print(f"Failed to import module '{module_name}': {e}")

    return mag_modules

# Example usage:
print("hola ************")
imported_modules = import_mag_modules_and_run_commands()
print(imported_modules)
# Now 'imported_modules' contains a dictionary of dynamically imported modules
# and click.commands for each method in those modules

