import requests
from requests import Response
from pydantic import Field

from dagster import ConfigurableResource


class DPGResource(ConfigurableResource):
    """
    Annotation
    """
    dpga_api_base_url: str = Field(
        description=(
            "URL for the DPGA API"
        ),
        default="https://app.digitalpublicgoods.net/api"
    )

    def get_list_from_dpga(self, stage="dpgs") -> Response:
        """
          Calls the dpg API and returns the Response object
        """ 
        url = f"{self.dpga_api_base_url}/{stage}"
        return requests.get(url)



