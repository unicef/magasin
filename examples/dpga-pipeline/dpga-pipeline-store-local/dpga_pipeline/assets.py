import requests
import pandas as pd
from pandas import DataFrame

from dagster import asset

@asset
def raw_dpgs() -> DataFrame:
  """ DPGs data from the API"""
  dpgs_json_dict = requests.get("https://api.digitalpublicgoods.net/dpgs").json()
  df = pd.DataFrame.from_dict(dpgs_json_dict)
  return df

@asset
def deployment_countries(raw_dpgs: DataFrame) -> DataFrame:
  df = raw_dpgs
  df_loc = pd.merge(df, pd.json_normalize(df["locations"]), left_index=True, right_index=True)
  df_deployment_countries = df_loc.explode("deploymentCountries")
  df_deployment_countries[["name","deploymentCountries"]]

  return df_deployment_countries