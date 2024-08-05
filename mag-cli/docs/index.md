# mag-CLI reference documentation

Welcome to the reference documentation for the command line interface (CLI) of [magasin](../). 

**mac-cli** is a very useful tool for system administrators that are managing a magasin instance. It provides shortcuts for common sys admin functions.

**Mag-cli** is written in python and uses [click](https://click.palletsprojects.com/) as core framework for building the interface.


!!! note
  
    This documentation is meant to be consumed by developers. 


Generally you'll [install mag-cli together with an instance of magasin](../install/). But if you need to **install mag-cli as standalone utility**  just run:

```sh
pip install mag-cli
```
You have examples on how to use the command line in [magasin's overall getting started](../get-started/).

Learn more about magasin:

* [What is magasin](../why-magasin.html)
* [Magasin Docs](../docs-home.html)
* [Contributing](../contributing)

## Intro to code structure

**mag-cli** is based on [click](https://click.palletsprojects.com/) a python package for creating command line interfaces in a composable way with as little code as necessary. Having some knowledge on how click works will ease the trip to understand mag-cli.

 Mag-cli has been though to be modular so that, as magasin components grow, mag-cli can also grow. The idea behind this modularity is founded in the [loosely-coupled architecture](../architecture.html).
 
 The code has a main core module [mag_core](mag_core) that has common and shared functionality across modules, and sets the scaffolding of the CLI. For example it enables '--version' to display the version of the CLI.
 
Then each magasin component has its own module that corresponds to one of the first level commands (`mag <first-level-command>`). For example, for Apache Superset, the [`mag_superset`](mag_superset) module enables all commands under `mag superset`

```sh
$ mag superset 

Usage: mag superset [OPTIONS] COMMAND [ARGS]...

  Apache Superset commands

Options:
  -r, --realm TEXT  magasin realm  [default:
                    magasin]
  --help            Show this message and exit.

Commands:
  ui  Launch Superset user interface
```
