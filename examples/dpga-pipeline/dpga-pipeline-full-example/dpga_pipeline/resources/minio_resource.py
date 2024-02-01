"""
MinIO Resource Definitions
"""
from minio import Minio

from pydantic import Field, PrivateAttr

from dagster import ConfigurableResource, InitResourceContext

class MinioResource(ConfigurableResource):
    """
    A resource for reading and writing in MinIO
    """
    endpoint: str = Field(
        description=(
            "Endpoint"
        ),
        default="localhost:9000"
    )

    access_key: str = Field(
        description=(
            "Minio username or access_key"
        ),
        default="minio"
    )
    secret_key: str = Field(
        description=(
            "Minio password or secret_key"
        ),
        default="minio123"
    )
    bucket: str = Field(
        description=(
            "Name of the bucket"
        ),
        default="magasin"
    )

    secure: bool = Field(
        description=(
            "Flag to indicate to use secure (TLS) connection to S3 service or not."
        ),
        default=False
    )

    cert_check: bool = Field(
        description=(
            "Validate the certificate of the endpoint? Set to false for self signed certificates."
        ),
        default=False
    )
    _client: Minio = PrivateAttr()

    def get_minio_client(self):
        """ returns an initialized minio client"""
        return self._client

    def setup_for_execution(self, context: InitResourceContext) -> None:
        """
        Initialize the resource. 
        Setups the minio client
        """
        # setup the client
        context.log.info("Setup for execution MinIO")
        self._client= Minio("localhost:9000",
                            access_key=self.access_key,
                            secret_key=self.secret_key,
                            secure=self.secure,
                            cert_check=self.cert_check)
