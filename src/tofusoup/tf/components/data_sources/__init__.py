"""TofuSoup Terraform provider data sources."""

from tofusoup.tf.components.data_sources import provider_info, provider_versions

__all__ = ["provider_info", "provider_versions"]
