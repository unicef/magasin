"""
MinIO Manager Resource

Manages input and output
"""
import io
import pandas as pd
from pandas import DataFrame
from dagster import OutputContext,InputContext, AssetKey, ConfigurableIOManager
from .minio_resource import MinioResource

class MinioJSONIOManager(ConfigurableIOManager):
    """
    Manages input and output for JSON files. 
    """

    minio_resource: MinioResource
    """
    Holds the information to access the MinIO server
    """

    root_path: str = ''
    """
    Path within the bucket to store the objects
    """

    def _get_path(self, asset_key: AssetKey, file_extension=".json") -> str:
        return self.root_path + "/".join(asset_key.path) + file_extension

    def handle_output(self, context: OutputContext, obj: DataFrame):

        # Sneak peak the obj
        #context.log.info(obj)

        # Bucket Name
        bucket = self.minio_resource.bucket

        # Minio Client
        client = self.minio_resource.get_minio_client()

        # file path
        path = self._get_path(context.asset_key)

        obj_data = io.BytesIO()
        obj.to_json(obj_data)

        # Reset the buffer position to the beginning before uploading
        obj_data.seek(0)

        # Put the object in the data store
        client.put_object(bucket, path,
                          data=obj_data, length=len(obj_data.getvalue()))

    def load_input(self, context: InputContext) -> DataFrame:
        """Loads the pandas DataFrame from a Minio bucket json file
    
        Returns:
            DataFrame
        """
        # Bucket Name
        bucket = self.minio_resource.bucket

        # get the MinIO Client
        client = self.minio_resource.get_minio_client()

        # Get the path of the json file
        object_path = self._get_path(context.asset_key)

        # Load from the bucket
        response = client.get_object(bucket, object_path)

        # Save it
        df = pd.read_json(response)
        return df



class MinioJSONParquetIOManager(MinioJSONIOManager):
    """
    Manages input as Json and output as a parquet file.
    """

    def handle_output(self, context: OutputContext, obj: DataFrame):
        """
        Writes to the minio server the contents of the dataframe as
        parquet file. Uses the name of the asset as filename
        """
        # Sneak peak the obj
        #context.log.info(obj)
    
        # Bucket Name
        bucket = self.minio_resource.bucket

        # Minio Client
        client = self.minio_resource.get_minio_client()

        obj_data = io.BytesIO()
        obj.to_parquet(obj_data)
        
        # Get the file path
        path = self._get_path(context.asset_key)

        # Reset the buffer position to the beginning before uploading
        obj_data.seek(0)

        # Put the object in the data store
        client.put_object(bucket, path,
                          data=obj_data, length=len(obj_data.getvalue()))
