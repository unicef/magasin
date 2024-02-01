# dpga-pipeline-full-example

This is a [Dagster](https://dagster.io) project that loads data form the DPGA pipeline and stores it in a Minio/S3 bucket.

This version of the pipeline uses more advanced concepts such as IOManagers, ConfigurableResources and asset Metadata.

This is part of the getting started tutorial of [magasin](http://magasin.github.io/get-started/) 

## Usage

1. Git clone the repository and go to the pipeline folder

    ```sh
    git clone https://github.com/unicef/magasin
    
    cd magasin/examples/dpga-pipeline/dpga-pipeline-full-example
    ```

2. Install the python package in editable mode. This allows you to run and edit the project at the same time.
    
    ```sh
    pip install -e ".[dev]"
    ```

3. Then, start the Dagster UI web server:

    ```sh
    dagster dev
    ```

4. Open http://localhost:3000 with your browser to see the project.


### Setting the environment variables

By default the MinioResource connects to a localhost server at port 9000 to the "magasin" bucket using minio/minio123 as credentials.

You can change these values by setting up environment variables. You have `.env-example` file as example.



```sh
dagster dev
```

## Development

You can start writing assets in `dpga_pipeline/assets.py`. The assets are automatically loaded into the Dagster code location as you define them.


### Adding new Python dependencies

You can specify new Python dependencies in `setup.py`.

### Unit testing

Tests are in the `dpga_pipeline_tests` directory and you can run tests using `pytest`:

```bash
pytest dpga_pipeline_tests
```
