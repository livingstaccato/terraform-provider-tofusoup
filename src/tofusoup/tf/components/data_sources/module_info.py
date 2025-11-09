"""Data source for querying module information from Terraform or OpenTofu registry.

This module provides the ModuleInfoDataSource class for retrieving detailed
information about a specific Terraform/OpenTofu module from registry APIs.
"""

from __future__ import annotations

from typing import Any, cast

from attrs import define
from pyvider.resource import DataSource, ResourceContext
from pyvider.schema import (
    a_bool,
    a_num,
    a_str,
    s_data_source,
)
from pyvider.types import DataSourceSchema

from tofusoup.registry.clients.opentofu import OpenTofuRegistry
from tofusoup.registry.clients.terraform import IBMTerraformRegistry
from tofusoup.registry.config import RegistryConfig

# Registry URLs
TERRAFORM_REGISTRY_URL = "https://registry.terraform.io"
OPENTOFU_REGISTRY_URL = "https://registry.opentofu.org"


@define(frozen=True)
class ModuleInfoConfig:
    """Configuration attributes for module_info data source.

    Attributes:
        namespace: Module namespace (e.g., "terraform-aws-modules")
        name: Module name (e.g., "vpc")
        provider: Target provider (e.g., "aws")
        registry: Registry to query - "terraform" or "opentofu" (default: "terraform")
    """

    namespace: str
    name: str
    provider: str
    registry: str | None = "terraform"


@define(frozen=True)
class ModuleInfoState:
    """State attributes for module_info data source.

    Attributes:
        namespace: Module namespace
        name: Module name
        provider: Target provider
        registry: Registry queried
        version: Latest version string
        description: Module description
        source_url: Source repository URL
        downloads: Total download count
        verified: Whether module is verified
        published_at: Publication date string
        owner: Module owner/maintainer
    """

    namespace: str | None = None
    name: str | None = None
    provider: str | None = None
    registry: str | None = None
    version: str | None = None
    description: str | None = None
    source_url: str | None = None
    downloads: int | None = None
    verified: bool | None = None
    published_at: str | None = None
    owner: str | None = None


# Type alias for the schema
MiSchema = DataSourceSchema[ModuleInfoConfig, ModuleInfoState]


class ModuleInfoDataSource(DataSource[ModuleInfoConfig, ModuleInfoState]):
    """Data source for querying module information from Terraform or OpenTofu registry.

    ## Example Usage

    ```terraform
    # Query VPC module from Terraform registry
    data "tofusoup_module_info" "vpc" {
      namespace = "terraform-aws-modules"
      name      = "vpc"
      provider  = "aws"
      registry  = "terraform"
    }

    output "vpc_source" {
      description = "VPC module source repository"
      value       = data.tofusoup_module_info.vpc.source_url
    }

    output "vpc_downloads" {
      description = "Total VPC module downloads"
      value       = data.tofusoup_module_info.vpc.downloads
    }

    # Query compute module from OpenTofu registry
    data "tofusoup_module_info" "compute" {
      namespace = "Azure"
      name      = "compute"
      provider  = "azurerm"
      registry  = "opentofu"
    }
    ```

    ## Argument Reference

    - `namespace` - (Required) Module namespace (e.g., "terraform-aws-modules")
    - `name` - (Required) Module name (e.g., "vpc")
    - `provider` - (Required) Target provider (e.g., "aws")
    - `registry` - (Optional) Registry to query: "terraform" or "opentofu", default: "terraform"

    ## Attribute Reference

    - `version` - Latest version string
    - `description` - Module description
    - `source_url` - Source repository URL
    - `downloads` - Total download count
    - `verified` - Whether module is verified
    - `published_at` - Publication date string (ISO 8601 format)
    - `owner` - Module owner/maintainer username
    """

    @classmethod
    def get_schema(cls) -> MiSchema:
        """Return the schema for module_info data source.

        Returns:
            Data source schema with configuration and state attributes.
        """
        return s_data_source(
            attributes={
                # Configuration (input) attributes
                "namespace": a_str(
                    required=True,
                    description="Module namespace (e.g., 'terraform-aws-modules')",
                ),
                "name": a_str(
                    required=True,
                    description="Module name (e.g., 'vpc')",
                ),
                "provider": a_str(
                    required=True,
                    description="Target provider (e.g., 'aws')",
                ),
                "registry": a_str(
                    optional=True,
                    default="terraform",
                    description="Registry to query: 'terraform' or 'opentofu'",
                ),
                # Computed (output) attributes
                "version": a_str(
                    computed=True,
                    description="Latest version string",
                ),
                "description": a_str(
                    computed=True,
                    description="Module description",
                ),
                "source_url": a_str(
                    computed=True,
                    description="Source repository URL",
                ),
                "downloads": a_num(
                    computed=True,
                    description="Total download count",
                ),
                "verified": a_bool(
                    computed=True,
                    description="Whether module is verified",
                ),
                "published_at": a_str(
                    computed=True,
                    description="Publication date string (ISO 8601 format)",
                ),
                "owner": a_str(
                    computed=True,
                    description="Module owner/maintainer username",
                ),
            }
        )

    async def read(self, ctx: ResourceContext) -> ModuleInfoState:
        """Read module information from the registry.

        Args:
            ctx: Resource context containing configuration.

        Returns:
            State with module information.

        Raises:
            Exception: If module not found or registry API error.
        """
        config = cast(ModuleInfoConfig, ctx.config)

        # Construct module identifier for version query
        module_id = f"{config.namespace}/{config.name}/{config.provider}"

        # Determine which registry to use
        if config.registry == "opentofu":
            registry_config = RegistryConfig(base_url=OPENTOFU_REGISTRY_URL)
            async with OpenTofuRegistry(registry_config) as registry:
                # Get latest version first
                versions = await registry.list_module_versions(module_id)
                if not versions:
                    raise ValueError(f"No versions found for module {module_id}")
                latest_version = versions[0].version

                # Get module details for latest version
                details = await registry.get_module_details(
                    config.namespace,
                    config.name,
                    config.provider,
                    latest_version,
                )
        else:
            registry_config = RegistryConfig(base_url=TERRAFORM_REGISTRY_URL)
            async with IBMTerraformRegistry(registry_config) as registry:
                # Get latest version first
                versions = await registry.list_module_versions(module_id)
                if not versions:
                    raise ValueError(f"No versions found for module {module_id}")
                latest_version = versions[0].version

                # Get module details for latest version
                details = await registry.get_module_details(
                    config.namespace,
                    config.name,
                    config.provider,
                    latest_version,
                )

        # Extract fields from the API response
        return ModuleInfoState(
            namespace=config.namespace,
            name=config.name,
            provider=config.provider,
            registry=config.registry,
            version=details.get("version"),
            description=details.get("description"),
            source_url=details.get("source"),
            downloads=details.get("downloads"),
            verified=details.get("verified"),
            published_at=details.get("published_at"),
            owner=details.get("owner"),
        )
