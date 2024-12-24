"""
Example of Pipeline for magasin 

https://unicef.github.io/magasin
"""

import datetime
from typing import List, Dict

import pandas as pd
from pandas import DataFrame

from dagster import asset, AssetExecutionContext, MetadataValue

from .resources import DPGResource


def get_today() -> str:
    """
    Obtains today's date returned as string in the format YYYY-MM-DD.
    """
    return datetime.date.today().strftime('%Y-%m-%d')


def add_timestamp(df: DataFrame) -> DataFrame:
    """ 
    Adds a timestamp column. This will allow us to have time series in the future
    """
    df["timestamp"]=pd.Timestamp.now()
    return df

def normalize_columns(df: DataFrame, column_list: List) -> DataFrame:
    ''' Normalizes the columns of a particular DataFrame. Each column in `column_list` is 
    expected to have a json object. This function will extract each attribute in those objects
    as a new column.
    '''
    for column in column_list:
        df = pd.merge(df, pd.json_normalize(df[column]), left_index=True, right_index=True)
    return df


def explode_columns(df: DataFrame, columns_to_explode,
                    other_columns=['id','name', 'website', 'stage','timestamp']):
    """Explodes the columns that are arrays in the DataFrame. It creates one row
      of for each item repeating the rest of the information on the column.

    Args:
        df (DataFrame): is the DataFrame to explode
        columns_to_explode (list, optional):is an array of columns to explode. Defaults to [].
        other_columns (list, optional): other columns to include from the original 
            DataFrame in the output DataFrame. 
            Defaults to ['id','name', 'website', 'stage','timestamp'].

    Returns:
        DataFrame: exploded DataFrame. It includes the exploded columns and `other_columns`
    """

    df2 = df
    for col in columns_to_explode:
        df2 = df2.explode(col)
    return df2[ other_columns + columns_to_explode]

def handle_inconsistent_types(df, column_name):
    """
    Handle inconsistent types in a DataFrame column.

    This function checks if the values in a specified column are lists.
    If a value is not a list, it is replaced with an empty list.

    Parameters:
    - df (pandas.DataFrame): The input DataFrame.
    - column_name (str): The name of the column to handle.

    Returns:
    pandas.DataFrame: A DataFrame with consistent types in the specified column.

    Example:
    >>> df = pd.DataFrame({'column1': [1, 2, 3], 'column2': ['A', 'B', 'C'], 'aliases': ['', [], ['X', 'Y']]})
    >>> handle_inconsistent_types(df, 'aliases')
    """
    df[column_name] = df[column_name].apply(lambda x: x if isinstance(x, list) else [])
    return df


def apply_transformations(dpg_api_json_dict: Dict) -> DataFrame:
    """
    Apply transformations to a DataFrame created from a DPG API JSON dictionary.

    This function takes a dictionary obtained from a DPG (Data Protection Gateway) API response,
    converts it into a DataFrame, performs various transformations including adding a 
    timestamp column, expanding columns containing objects, handling inconsistent
    types, and fixing character issues. The resulting DataFrame is returned.

    Parameters:
    - dpg_api_json_dict (dict): Dictionary obtained from the DPG API response.

    Returns:
    pandas.DataFrame: Transformed DataFrame.
    """

    # Convert to DataFrame
    df = pd.DataFrame.from_dict(data=dpg_api_json_dict)

    # Add a timestamp column so that we can perform time series
    df = add_timestamp(df)

    # Expand the columns that contain objects
    df = normalize_columns(df, ['platformIndependence', 'locations', 'sdgs', 'dataPrivacySecurity',\
                                  'NonPII', 'protectionFromHarassment', 'userContent' ])

    # The json response inconsistently mixes [] or "" for empty values in several columns.
    df = handle_inconsistent_types(df, 'aliases')
    df = handle_inconsistent_types(df, 'deploymentOrganisations')
    df = handle_inconsistent_types(df, 'deploymentCountriesDepartments')
    df = handle_inconsistent_types(df, 'otherDeploymentOrganisations')
    df = handle_inconsistent_types(df, 'awardsReceived')

    return df


@asset(io_manager_key="minio_json_io_manager")
def raw_dpgs(context: AssetExecutionContext, dpg_api: DPGResource) -> DataFrame:
    """
    The original list of dpgs but for those columns that are objects 
    extracted are expanded into separated columns for each item.
    """

    # Get the json from the API
    dpgs_json_dict = dpg_api.get_list_from_dpga().json()

    df = apply_transformations(dpgs_json_dict)

    # Put some metadata
    context.add_output_metadata(
        metadata={
            "number_of_dpgs": len(dpgs_json_dict),
            "loaded_json_preview": MetadataValue.json(dpgs_json_dict[:5]),
            "output_preview": MetadataValue.md(df.head().to_markdown())
        })
    return df

@asset(io_manager_key="minio_json_parquet_io_manager")
def deployment_countries( context: AssetExecutionContext, raw_dpgs: DataFrame,
                         ) -> DataFrame:
    """
    For each country in which there is a deployment of a DPG it has a row 
    with the name of the country and the DPG
    """

    # Explode the deployment countries.
    # The column deploymentCountries is an array.
    # For each item in the array, this function will create a copy of
    # each row.
    df = explode_columns(raw_dpgs,['deploymentCountries'])

    # Adds some metadata to be displayed in Dagster UI
    context.add_output_metadata(
        metadata={
            "number_of_deployments": len(df),
            "preview": MetadataValue.md(df.head().to_markdown())
        }
    )
    return df

@asset(io_manager_key="minio_json_parquet_io_manager")
def development_countries(context: AssetExecutionContext,
                          raw_dpgs: DataFrame,
                          ) -> DataFrame:
    """
    For each country in which the DPG has been developed it has a row
    """
    df = explode_columns(raw_dpgs,['developmentCountries'])

    context.add_output_metadata(
        metadata={
            "number_of_deployments": len(df),
            "preview": MetadataValue.md(df.head().to_markdown()),
        }
    )
    return df


@asset(io_manager_key="minio_json_parquet_io_manager")
def categories(context: AssetExecutionContext,
                          raw_dpgs: DataFrame,
                          ) -> DataFrame:
    """
    For each category a DPG belongs to has a Row.
    """
    df = explode_columns(raw_dpgs,['categories'])

    context.add_output_metadata(
        metadata={
            "dpgs_exploded_by_category": len(df),
            "preview": MetadataValue.md(df.head().to_markdown()),
        }
    )
    return df

@asset(io_manager_key="minio_json_parquet_io_manager")
def sdg(context: AssetExecutionContext,
                          raw_dpgs: DataFrame,
                          ) -> DataFrame:
    """
    For each SDG a DPG belongs to it has a row.
    """
    df = explode_columns(raw_dpgs,['sdg'])

    # There is an issue with the ',' character. We fix it.
    df['sdg'] = df['sdg'].str.replace('¸', ',')
    df['sdg'] = df['sdg'].str.replace('&#184;', ',')

    context.add_output_metadata(
        metadata={
            "dpgs_exploded_by_sdg": len(df),
            "preview": MetadataValue.md(df.head().to_markdown()),
        }
    )
    return df


@asset(io_manager_key="minio_json_parquet_io_manager")
def open_licenses(context: AssetExecutionContext,
                          raw_dpgs: DataFrame,
                          ) -> DataFrame:
    """
    For each Open License supported by the DPG it has a row.
    """

    # Open Licenses is an array of objects with the form:
    #
    # "openlicenses": [
    #        {
    #            "openLicense": "AGPL-3.0",
    #            "openLicenseEvidenceURLs": "https://github.com/.../whatever1"
    #        },
    #        {
    #            "openLicense": "BSD-2-Clause",
    #            "openLicenseEvidenceURLs": "https://github.com/.../whatever"
    #        }
    #    ],
    #
    # So we need to explode the column so we get one row per item in the array
    # and then normalize to get one column per attribute (i.e.,
    # openLicense and openLicenseEvidenceUrls)

    df = normalize_columns(explode_columns(raw_dpgs, ['openlicenses']).reset_index(drop=True),
                           ['openlicenses'])

    context.add_output_metadata(
        metadata={
            "dpgs_exploded_by_sdg": len(df),
            "preview": MetadataValue.md(df.head().to_markdown()),
        }
    )
    return df


@asset(io_manager_key="minio_json_parquet_io_manager")
def clear_ownership(context: AssetExecutionContext,
                          raw_dpgs: DataFrame,
                          ) -> DataFrame:
    """Provides one row per organizations that is pushing for a particular DPG"""
    # Same as open_licenses

    df = normalize_columns(explode_columns(raw_dpgs, ['clearOwnership']).reset_index(drop=True),
                           ['clearOwnership'])

    context.add_output_metadata(
        metadata={
            "rows ": len(df),
            "preview": MetadataValue.md(df.head().to_markdown())
        })

    return df
