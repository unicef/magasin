import fsspec
import requests
import pandas as pd
from pandas import DataFrame
from dagster import asset

@asset
def raw_dpgs() -> DataFrame:
  """ DPGs data from the API"""
  # Load from API
  dpgs_json_dict = requests.get("https://api.digitalpublicgoods.net/dpgs").json()  

  # Convert to pandas dataframe
  df = pd.DataFrame.from_dict(dpgs_json_dict)
  return df

@asset
def deployment_countries(raw_dpgs: DataFrame) -> DataFrame:
   
  df = raw_dpgs
  df_loc = pd.merge(df, pd.json_normalize(df["locations"]), left_index=True, right_index=True)
  df_deployment_countries = df_loc.explode("deploymentCountries")
  df_deployment_countries = df_deployment_countries[["id", "name","deploymentCountries"]]
  
  # Save to MinIO
  fs= fsspec.filesystem('s3')
  with fs.open('/magasin/data/deployment_countries.parquet','wb') as f:
    df_deployment_countries.to_parquet(f)
    
  return df_deployment_countries