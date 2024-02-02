# Superset DPGA dashboard

This is the final dashboard displayed on the [step 3 of the magasin getting started tutorial](https://unicef.github.io/magasin/get-started/create-a-dashboard.html). 

In order to work as it is, it assumes that you installed magasin in the `magasin` realm, following the get started, and you followed the previous the steps [magasin get started tutorial](https://unicef.github.io/magasin/get-started/tutorial-overview.html). That is there is an instance of Apache Drill is installed in the namespace `magasin-drill` that has a storage called `s3` with a workspace called `data`, that holds a file called `deployment_countries.parquet`.

Alternatively, you can upload to superset the file [deployment_countries.parquet](./deployment_countries.parquet) to superset and replace the dataset of the Charts.

If everything works ok you should be able to see the following image:

  ![Superset Dashboard](./superset-final-dashboard.png)


## How to import the dashboard

1. Download the file [dpga-superset-dashboard.zip](dpga-superset-dashboard.zip).

2. In superset, import the dashboard:
  
    ![steps to import the dashboard](./superset-import-dashboard.png)



