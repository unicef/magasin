# United Nations exchange rates _paquet_

This _paquet_ includes the official exchange rates of the United Nations.


## Dataset

The extracted ready-to-use dataset is composed by files with the name `un_exchange_rate_yyyy-mm-dd.parquet`. Each file has the following fields:

* CountryName (String, English name)
* CurrencyCode (3 letter)
* CurrencyName (String, English name)
* ExchangeRate (Float)
* Date (Date)

See example files:

* [un_exchange_rate_2021-01-01.parquet](./un_exchange_rate_example_file.parquet)

* [un_exchange_rate_2021-01-01.csv](./un_exchange_rate_example_file.csv)

The UN updates the exchange rates around twice a month, day 1 and 15. 
## Data Source
https://treasury.un.org/operationalrates/OperationalRates.php

## Folder Contents
* **exploration/** folder contains the Jupyter notebook used to explore the dataset. It explains all the steps to clean and prepare the data. 

* **pipeline/** folder contains the Dagster pipeline that will get new data from the source and update the dataset.

* **dashboard/** folder contains the Superset dashboard that shows the data in a visual way.


## Usage with magasin



## Step 1: Get the data
First, clone the repo

```sh 
git clone https://github.com/unicef/magasin 
```

Then go to `magasin/examples/un-currency-exchange`.

If you want to get the historical data since 2014, then you need to run all the cells in the `un-currecy-exchange.ipynb` notebook. Within the `explorations/data` folder. It will download extract all the data from the UN website. 

### Step 2: Load the data into a MinIO bucket

In this step, you move the historical data into MinIO. 

```sh
# Create the bucket un-exchange-rates in minio
 mag minio add bucket --bucket-name un-exchange-rates

# Launch the minio API server, so we can copy the data to the bucket
# this is required for mc command to work.
mag minio api 
``` 

In another console terminal go to the data folder (`magasin/examples/un-currency-echange/explorations/data`) and copy 

```sh

mc cp *.parquet myminio/un-echange-rates/
```

### Step 3: Create the connection in Apache Drill 

Now, let's create the connection in Apache Drill to the minio bucket. 

Run 
```sh
mag drill ui
```

This will open a new tab in your browser. Go to the **storage** tab and click on the **Create** button to add a new storage plugin.

Set the name as `unexchangerates` (avoid symbols in the name), and the configuration with the following information


```json
{
  "type": "file",
  "connection": "s3a://un-exchange-rates",
  "config": {
    "fs.s3a.connection.ssl.enabled": "false",
    "fs.s3a.path.style.access": "true",
    "fs.s3a.endpoint": "myminio-hl.magasin-tenant.svc.cluster.local:9000",
    "fs.s3a.access.key": "minio",
    "fs.s3a.secret.key": "minio123"
  },
  "workspaces": {
    "data": {
      "location": "/data",
      "writable": false,
      "defaultInputFormat": null,
      "allowAccessOutsideWorkspace": false
    },
    "root": {
      "location": "/",
      "writable": false,
      "defaultInputFormat": null,
      "allowAccessOutsideWorkspace": false
    }
  },
  "formats": {
    "parquet": {
      "type": "parquet"
    }
  },
  "authMode": "SHARED_USER",
  "enabled": true
}

```

To test the connection, click on the **Save** button and then go to the **Query** tab.

Run the following query to see if the connection is working:

```sql
USE `unexchangerates`;
```
It should display `Default schema changed to [unexchangerates]`



### Step 4: Create the Superset Dashboard

Create the database connection with the name "unexchangerates".

The type shall be "Apache Drill", and the connection string shall be this: 

```
drill+sadrill://drill-service.magasin-drill.svc.cluster.local:8047/unexchangerates?use_ssl=False
```


### Step 5: Add the pipeline to dagster

TODO 