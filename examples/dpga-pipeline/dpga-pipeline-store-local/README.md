# dpga-pipeline-store-local

This is the first version of the dpga pipeline  that is run in the [second step](httpa://magasin.github.io/get-started/automate-data-ingestion.html) of the [getting started tutorial](httpa://magasin.github.io/get-started/).  

Tested with `dagster==1.6.0` and `dagster-webserver==1.6.0`

## Usage

1. Clone the repo.

2. Go to the root folder of the pipeline (the same as this `README.md` file)

3. Run
    ```bash
    pip install -e ".[dev]"
    ```

4. Then, start the Dagster UI web server:

    ```bash
    dagster dev
    ```

5. Open http://localhost:3000 with your browser to see the project.





