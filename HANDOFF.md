# terraform-provider-tofusoup - Handoff Document

**Last Updated:** 2025-11-08
**Status:** Initial Setup Complete, Ready for Provider Implementation
**Current Phase:** Phase 1 - Foundation (Week 1)

---

## Project Overview

### Purpose
Create a Terraform provider that exposes TofuSoup's registry querying and state inspection capabilities as Terraform data sources.

### Scope
**In Scope:**
- Registry data sources (provider info, versions, module search)
- State inspection data sources (read state files)
- Provider configuration
- Documentation via Plating
- Build system via FlavorPack

**Out of Scope:**
- Testing features (matrix tests, conformance tests, stir tests)
- Resources (only data sources)
- Functions (future consideration)

---

## Key Architectural Decisions

### 1. Namespace Structure
**Decision:** Use `tofusoup.tf.components`
**Rationale:**
- User-centric (focuses on Terraform, not implementation framework)
- Clear expansion path (`tofusoup.tf.utils`, `tofusoup.tf.client`)
- Pyvider is an implementation detail

**Directory Structure:**
```
src/tofusoup/
└── tf/
    ├── __init__.py
    └── components/
        ├── __init__.py
        ├── provider.py
        └── data_sources/
            ├── __init__.py
            ├── provider_info.py
            ├── provider_versions.py
            ├── module_info.py
            ├── module_versions.py
            ├── module_search.py
            ├── registry_search.py
            ├── state_info.py
            ├── state_resources.py
            └── state_outputs.py
```

### 2. Configuration Files
**Decision:** Use `soup.toml` (not `tofusoup.toml`)
**Rationale:** Follows TofuSoup convention

### 3. Documentation Strategy
**Decision:** Use Plating for all documentation generation
**Rationale:**
- Automated doc generation from code
- Consistent with pyvider ecosystem
- Examples drive documentation

### 4. Build Strategy
**Decision:** FlavorPack for binary packaging
**Rationale:**
- Proven pattern from terraform-provider-pyvider
- Multi-platform support
- PSPF/2025 executable format

---

## Current Implementation Status

### ✅ Completed

1. **Repository Structure**
   - Created `/Users/tim/code/gh/provide-io/terraform-provider-tofusoup/`
   - Initialized git repository
   - Created complete directory structure:
     - `src/tofusoup/tf/components/data_sources/`
     - `tests/data_sources/`
     - `examples/provider/`, `examples/data-sources/`
     - `docs/`, `templates/`

2. **Configuration Files**
   - ✅ `pyproject.toml` - Python project configuration
   - ✅ `soup.toml` - Pyvider provider configuration
   - ✅ `.gitignore` - Git ignore patterns
   - ✅ `README.md` - Basic project documentation
   - ⏳ `Makefile` - **PENDING**

3. **Python Environment**
   - Virtual environment created at `.venv`
   - All dependencies installed:
     - pyvider (0.0.1102)
     - tofusoup (0.0.1101)
     - flavorpack (0.0.1026)
     - provide-foundation (0.0.1102)
     - plating (0.0.1100)
     - Dev tools: pytest, ruff, mypy, mkdocs

4. **Package Structure**
   - ✅ `src/tofusoup/__init__.py`
   - ✅ `src/tofusoup/tf/__init__.py`
   - ✅ `src/tofusoup/tf/components/__init__.py`
   - ✅ `src/tofusoup/tf/components/data_sources/__init__.py`
   - ✅ `tests/__init__.py`
   - ✅ `tests/data_sources/__init__.py`

### 🔄 In Progress

5. **Configuration Files (Continued)**
   - Need to create `Makefile`
   - Need to create `mkdocs.yml`

### ⏳ Pending

6. **Provider Implementation**
   - Provider component (`provider.py`)
   - Provider configuration schema
   - Provider docstring for Plating

7. **Data Sources - Registry** (6 total)
   - `tofusoup_provider_info`
   - `tofusoup_provider_versions`
   - `tofusoup_module_info`
   - `tofusoup_module_versions`
   - `tofusoup_module_search`
   - `tofusoup_registry_search`

8. **Data Sources - State Inspection** (3 total)
   - `tofusoup_state_info`
   - `tofusoup_state_resources`
   - `tofusoup_state_outputs`

9. **Examples & Documentation**
   - Provider example
   - Data source examples (one per data source)
   - Plating generation
   - MkDocs site configuration

10. **Testing**
    - Unit tests for data sources
    - Integration tests
    - Example validation

11. **Build System**
    - FlavorPack binary generation
    - Local installation testing
    - Multi-platform builds

---

## Dependencies & Integration Points

### Direct Dependencies
- **pyvider:** Provider framework, schema system, async base classes
- **tofusoup:** Registry clients, state inspection utilities
- **flavorpack:** Binary packaging and executable generation
- **plating:** Documentation generation from code
- **provide-foundation:** Logging and telemetry

### TofuSoup API Integration Points

**Registry Operations (Async):**
```python
from tofusoup.registry.terraform import TerraformRegistry
from tofusoup.registry.opentofu import OpenTofuRegistry

async with TerraformRegistry() as registry:
    details = await registry.get_provider_details(namespace, name)
    versions = await registry.list_provider_versions(namespace, name)
    modules = await registry.search_modules(query)
```

**State Inspection:**
```python
from tofusoup.state import StateInspector  # (verify actual API)

inspector = StateInspector(state_file_path)
metadata = inspector.get_metadata()
resources = inspector.list_resources()
```

### Async Compatibility
- ✅ TofuSoup registry clients are fully async
- ✅ Pyvider data sources support async `read()` methods
- ✅ Both use standard Python `asyncio` (not custom async framework)
- ✅ Both use `provide-foundation` for logging

---

## Development Workflow

### Setup (One-time)
```bash
cd /Users/tim/code/gh/provide-io/terraform-provider-tofusoup
source .venv/bin/activate
```

### Development Cycle
```bash
# 1. Implement component
# Edit src/tofusoup/tf/components/...

# 2. Format and lint
ruff format <file>
ruff check --fix --unsafe-fixes <file>
mypy <file>
ruff format <file>  # Again after fixes

# 3. Test
pytest tests/

# 4. Build and install locally
make build
make install

# 5. Test with Terraform
cd examples/data-sources/<datasource_name>
terraform init
terraform plan

# 6. Generate docs
make docs
make docs-serve  # Preview at localhost:8000
```

### Code Quality Standards
Per CLAUDE.md:
- Run `ruff format <file>` after editing
- Run `ruff check --fix --unsafe-fixes <file>`
- Run `mypy <file>` for type checking
- Run `ruff format <file>` again
- Changes are auto-committed (do NOT mention commits)

---

## Implementation Checklist

### Phase 1: Foundation (Week 1) - Current Focus

- [x] Repository structure
- [x] pyproject.toml
- [x] soup.toml
- [x] .gitignore
- [x] README.md
- [x] Python environment setup
- [x] Package __init__.py files
- [ ] **Makefile** ← NEXT
- [ ] **mkdocs.yml** ← NEXT
- [ ] **provider.py implementation** ← NEXT
- [ ] **tofusoup_provider_info data source** ← Week 1 MVP
- [ ] **tofusoup_provider_versions data source** ← Week 1 MVP
- [ ] Example for provider_info
- [ ] Build system working end-to-end
- [ ] First Plating docs generation

### Phase 2: Registry Features (Week 2)

- [ ] tofusoup_module_info
- [ ] tofusoup_module_versions
- [ ] tofusoup_module_search
- [ ] tofusoup_registry_search
- [ ] Examples for all registry data sources
- [ ] Complete registry documentation

### Phase 3: State Inspection (Week 3)

- [ ] tofusoup_state_info
- [ ] tofusoup_state_resources
- [ ] tofusoup_state_outputs
- [ ] Examples for state inspection
- [ ] Handle encrypted state files
- [ ] Error handling for invalid states

### Phase 4: Polish (Week 4)

- [ ] Complete all documentation
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] All examples validated
- [ ] Code quality (ruff + mypy clean)
- [ ] Release preparation

---

## Data Source Specifications

### 1. tofusoup_provider_info

**Purpose:** Query provider details from Terraform/OpenTofu registry

**Schema:**
```hcl
data "tofusoup_provider_info" "aws" {
  namespace = "hashicorp"  # Required
  name      = "aws"        # Required
  registry  = "terraform"  # Optional: "terraform" or "opentofu", default: "terraform"
}

# Computed attributes:
# - latest_version (string)
# - description (string)
# - source_url (string)
# - downloads (number)
# - published_at (string)
```

**Implementation:**
- Use `tofusoup.registry.terraform.TerraformRegistry` or `OpenTofuRegistry`
- Async `read()` method
- Cache responses based on provider config

### 2. tofusoup_provider_versions

**Purpose:** List all available versions of a provider

**Schema:**
```hcl
data "tofusoup_provider_versions" "aws" {
  namespace = "hashicorp"
  name      = "aws"
  registry  = "terraform"
}

# Computed:
# - versions (list(string))
# - version_details (list(object)) - includes protocols, platforms
```

### 3. tofusoup_module_info

**Purpose:** Get module details from registry

**Schema:**
```hcl
data "tofusoup_module_info" "vpc" {
  namespace = "terraform-aws-modules"
  name      = "vpc"
  provider  = "aws"
  registry  = "terraform"
}

# Computed:
# - latest_version
# - description
# - source_url
# - downloads
```

### 4. tofusoup_module_versions

**Purpose:** List module versions

**Schema:**
```hcl
data "tofusoup_module_versions" "vpc" {
  namespace = "terraform-aws-modules"
  name      = "vpc"
  provider  = "aws"
  registry  = "terraform"
}

# Computed:
# - versions (list(string))
```

### 5. tofusoup_module_search

**Purpose:** Search for modules by query

**Schema:**
```hcl
data "tofusoup_module_search" "vpc" {
  query    = "aws vpc"
  registry = "terraform"
  limit    = 10  # Optional, default: 20
}

# Computed:
# - modules (list(object)) - namespace, name, provider, description, downloads
```

### 6. tofusoup_registry_search

**Purpose:** Search for providers by query

**Schema:**
```hcl
data "tofusoup_registry_search" "cloud" {
  query    = "aws"
  registry = "terraform"
  type     = "provider"  # or "module"
  limit    = 10
}

# Computed:
# - results (list(object))
```

### 7. tofusoup_state_info

**Purpose:** Read Terraform state file metadata

**Schema:**
```hcl
data "tofusoup_state_info" "current" {
  state_file = "terraform.tfstate"  # Required: path to state file
}

# Computed:
# - terraform_version (string)
# - serial (number)
# - lineage (string)
# - resource_count (number)
# - resources (list(string)) - resource addresses
```

### 8. tofusoup_state_resources

**Purpose:** List resources in state file

**Schema:**
```hcl
data "tofusoup_state_resources" "all" {
  state_file  = "terraform.tfstate"
  filter_type = "aws_instance"  # Optional: filter by resource type
}

# Computed:
# - resources (list(object)) - full resource data
```

### 9. tofusoup_state_outputs

**Purpose:** Read outputs from state file

**Schema:**
```hcl
data "tofusoup_state_outputs" "current" {
  state_file = "terraform.tfstate"
}

# Computed:
# - outputs (map(any)) - output name -> value
```

---

## Provider Configuration

**Provider Schema:**
```python
@attrs.define
class TofuSoupProviderConfig:
    cache_dir: str | None = None
    cache_ttl_hours: int = 24
    terraform_registry_url: str = "https://registry.terraform.io"
    opentofu_registry_url: str = "https://registry.opentofu.org"
    log_level: str = "INFO"
```

**Usage in Terraform:**
```hcl
provider "tofusoup" {
  cache_dir               = "/tmp/tofusoup-cache"
  cache_ttl_hours         = 24
  terraform_registry_url  = "https://registry.terraform.io"
  opentofu_registry_url   = "https://registry.opentofu.org"
  log_level               = "INFO"
}
```

---

## Plating Documentation Requirements

### Docstring Format for Components

**Provider Example:**
```python
"""
Provider docstring with description.

## Example Usage

```terraform
provider "tofusoup" {
  cache_dir = "/tmp/cache"
}
```

## Configuration

- `cache_dir` - (Optional) Cache directory path
- `cache_ttl_hours` - (Optional) Cache TTL in hours
...
"""
```

**Data Source Example:**
```python
"""
Data source description.

Returns detailed information about...

## Example Usage

```terraform
data "tofusoup_provider_info" "aws" {
  namespace = "hashicorp"
  name      = "aws"
}

output "version" {
  value = data.tofusoup_provider_info.aws.latest_version
}
```

## Argument Reference

- `namespace` - (Required) Provider namespace
- `name` - (Required) Provider name
...

## Attribute Reference

- `latest_version` - Latest version string
- `description` - Provider description
...
"""
```

### Example Structure for Plating

```
examples/
├── provider/
│   ├── provider.tf              # Shows provider config
│   └── README.md
└── data-sources/
    ├── tofusoup_provider_info/
    │   ├── main.tf              # Terraform config
    │   ├── outputs.tf           # Output definitions
    │   └── README.md            # Example explanation
    └── tofusoup_module_search/
        ├── main.tf
        ├── outputs.tf
        └── README.md
```

### Generating Documentation

```bash
# Generate docs from code + examples
plating plate --provider-name tofusoup

# Output location
docs/
├── index.md                     # Auto-generated
├── provider.md                  # Auto-generated
└── data-sources/
    ├── tofusoup_provider_info.md
    └── ...
```

---

## Build & Installation

### Makefile Targets (To Be Created)

```makefile
build:       # Build wheel + FlavorPack binary
install:     # Install to ~/.terraform.d/plugins/
test:        # Run pytest
docs:        # Generate with Plating
docs-serve:  # Serve docs locally
clean:       # Clean build artifacts
```

### Local Installation Path

```
~/.terraform.d/plugins/local/providers/tofusoup/0.1.0/darwin_arm64/
└── terraform-provider-tofusoup
```

### Testing Provider Locally

```hcl
terraform {
  required_providers {
    tofusoup = {
      source  = "local/providers/tofusoup"
      version = "0.1.0"
    }
  }
}
```

---

## Known Constraints & Requirements

### From CLAUDE.md

**Global (.claude/CLAUDE.md):**
- ❌ Do NOT roll back in git (autocommitted)
- ❌ Do NOT mention git commits in output
- ❌ Refrain from mentioning yourself in commits

**Project (provide-io/CLAUDE.md):**
- ✅ Do NOT update venv files directly
- ✅ Changes are autocommitted but NOT auto-pushed
- ✅ When writing Python, run in sequence:
  1. `ruff format <file>`
  2. `ruff check --fix --unsafe-fixes <file>`
  3. `mypy <file>`
  4. `ruff format <file>` (again)

---

## Open Questions & Decisions Needed

1. **Cache Strategy:**
   - Global cache shared across data sources?
   - Per-datasource cache isolation?
   - **Decision:** TBD during provider implementation

2. **State Encryption:**
   - Support encrypted Terraform state?
   - Use tofusoup's encryption utilities?
   - **Decision:** TBD during state_info implementation

3. **Error Handling:**
   - Network failure retry strategy?
   - Cache miss behavior?
   - **Decision:** TBD during implementation

4. **Version Compatibility:**
   - Support old Terraform state versions?
   - Which state file versions to target?
   - **Decision:** TBD during state inspection

---

## Next Steps (Immediate)

1. **Create Makefile** with build, install, test, docs targets
2. **Create mkdocs.yml** for documentation site
3. **Implement provider.py** with provider configuration schema
4. **Implement tofusoup_provider_info** (first data source)
5. **Create example** for provider_info
6. **Test end-to-end:** build → install → terraform init → plan
7. **Generate docs** with plating
8. **Iterate** on remaining data sources

---

## Success Metrics

### Week 1 MVP
- ✅ Provider builds successfully
- ✅ Installs to local Terraform plugin directory
- ✅ 2 data sources work (provider_info, provider_versions)
- ✅ Plating generates documentation
- ✅ At least 1 example runs successfully

### V1.0 Release
- ✅ All 9 data sources implemented
- ✅ All data sources have examples
- ✅ Complete Plating documentation
- ✅ All tests passing (unit + integration)
- ✅ Code quality clean (ruff + mypy)
- ✅ Published to GitHub releases

---

## References

### Related Projects
- **terraform-provider-pyvider:** `/Users/tim/code/gh/provide-io/terraform-provider-pyvider/`
- **pyvider:** `/Users/tim/code/gh/provide-io/pyvider/`
- **pyvider-components:** `/Users/tim/code/gh/provide-io/pyvider-components/`
- **tofusoup:** `/Users/tim/code/gh/provide-io/tofusoup/`
- **plating:** `/Users/tim/code/gh/provide-io/plating/`
- **flavorpack:** `/Users/tim/code/gh/provide-io/flavorpack/`

### Documentation
- Pyvider docs: Check `pyvider/docs/`
- TofuSoup docs: Check `tofusoup/README.md`
- Plating usage: Check `plating/README.md`

---

## Contact & Handoff

**Current State:** Repository initialized, dependencies installed, ready for provider implementation
**Next Developer:** Continue with Makefile → provider.py → first data source
**Environment:** `.venv` already set up, just `source .venv/bin/activate`

---

*End of Handoff Document*
