import importlib
import pkgutil


## TODO

def import_mgs_modules():
    """
    Dynamically import all modules in the current environment with names starting with "mgs.mgs_",
    and run click.command(method) for each method in those modules.

    Returns:
    - dict: A dictionary where keys are module names and values are the imported module objects.
    """
    mgs_modules = {}

    for module_info in pkgutil.iter_modules():
        print(module_info)
        if module_info.name.startswith("mgs.mgs_"):
            module_name = module_info.name
            try:
                module = importlib.import_module(module_name)
                mgs_modules[module_name] = module

                # Extract the method name (what is after "mgs_")
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

    return mgs_modules

# Example usage:
print("hola ************")
imported_modules = import_mgs_modules_and_run_commands()
print(imported_modules)
# Now 'imported_modules' contains a dictionary of dynamically imported modules
# and click.commands for each method in those modules

