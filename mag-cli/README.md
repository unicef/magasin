# Magasin Command Line Interface (mag)

Command line interface client that helps to manage the different modules of [magasin](http://github.com/unicef/magasin)

## Install

```sh
pip install mag-cli
```

## Usage

```sh
 mag
Usage: mag [OPTIONS] COMMAND [ARGS]...

  magasin client is the glue between magasin components, it makes easier
  common tasks

Options:
  -v, --verbose
  --version
  --help         Show this message and exit.

Commands:
  dagster (d)    Dagster commands
  daskhub (dh)   Daskhub/Jupyterhub commands
  drill (dr)     Apache Drill commands
  minio (m)      MinIO commands
  superset (ss)  Apache Superset commands
```

You have an example on how this client is used in real life in the [get started with magasin](https://unicef.github.io/magasin/)

## Development 

Clone the repo
```sh
git clone https://github.com/unicef/magasin
```
Create and activate the virtual environment
```sh
cd magasin/mag-cli
python -m venv venv
source venv/bin/activate
```

Install module in editing mode
```sh
pip install -e '.[dev]'
```

Start coding!


## Reference documentation

You have available the [reference documentation online](https://unicef.github.io/mag-cli/).

### Generate the reference documentation
The application uses [mkdocs]() for generating the technical documentation.

If you want to generate the documentation localy you need first to install `mkdocs`, `mkdocstrings` and `mkdocs-material`:

```sh
pip install mkdocs mkdocstrings mkdocs-material
```

Then you can serve the docs.
```sh
cd mac-cli
mkdocs serve
```

This will launch a server in http://localhost:8000.

### Build the docs

```sh
cd mac-cli
mkdocs build
```
This will create the folder `<local_repo_path>/mac-cli/site`. You can browse the documentation by opening the file `index.html` in your browser.

## License

Copyright 2024 United Nations Children's Fund (UNICEF)

Source code distributed under the [Apache 2.0 License](./LICENSE)
Documentation distributed under [Creative Commons CC-BY](https://creativecommons.org/licenses/by/4.0/)
