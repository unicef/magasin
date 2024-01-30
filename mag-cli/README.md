# Magasin Command Line Interface (mag)

Command line interface client that helps to manage the different modules of [magasin](http://github.com/unicef/magasin)

## Install

```sh
pip install mag
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


# Development 

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


