# terraform-provider-tofusoup - Part 13: state_resources Implementation

**Session Date:** 2025-11-09
**Items:** 61-68
**Summary:** Eighth data source with Terraform state resource listing and filtering

[← Back to Index](HANDOFF-INDEX.md)

---

## Implementation Details

### Part 13: tofusoup_state_resources Implementation (CURRENT SESSION)

61. ✅ **state_resources.py data source implementation**:
    - **Location**: `/Users/tim/code/gh/provide-io/terraform-provider-tofusoup/src/tofusoup/tf/components/data_sources/state_resources.py`
    - **Config Class**: `StateResourcesConfig` (state_path, filter_mode, filter_type, filter_module)
    - **State Class**: `StateResourcesState` (echoes filters, resource_count, resources[])
    - **Key Features**:
      - **Resource Listing**: Lists all resources from state file
      - **Flexible Filtering**: Filter by mode, type, and/or module
      - **Resource Metadata**: mode, type, name, provider, module, instance counts
      - **Instance Detection**: Identifies count/for_each resources
      - **Resource IDs**: Constructs unique identifiers
      - **ID Extraction**: Gets ID from first instance
    - **Filters Available**:
      - `filter_mode`: "managed" or "data" (resources vs data sources)
      - `filter_type`: Resource type (e.g., "aws_instance", "aws_vpc")
      - `filter_module`: Module path (e.g., "module.ec2_cluster")
      - Filters can be combined (AND logic)
    - **Resource Object Structure**:
      ```python
      {
          "mode": str,                    # "managed" or "data"
          "type": str,                    # Resource type
          "name": str,                    # Resource name
          "provider": str,                # Provider reference
          "module": str | None,           # Module path or null
          "instance_count": int,          # Number of instances
          "has_multiple_instances": bool, # True if count/for_each
          "resource_id": str,             # Unique identifier
          "id": str | None,               # ID from first instance
      }
      ```
    - **Resource ID Format**:
      - Root module: `{mode}.{type}.{name}`
      - In module: `{mode}.{module}.{type}.{name}`
      - Examples: `managed.aws_vpc.main`, `data.module.ec2.aws_ami.ubuntu`
    - **Implementation Approach**:
      - Load state file (same as state_info)
      - Extract resources array
      - Apply filters sequentially
      - Convert each resource to output format
      - Extract ID from first instance's attributes
      - Count instances to detect count/for_each usage
    - **Registered in**: `/Users/tim/code/gh/provide-io/terraform-provider-tofusoup/src/tofusoup/tf/components/data_sources/__init__.py`

62. ✅ **Comprehensive test suite** (30/30 tests passing):
    - **Location**: `/Users/tim/code/gh/provide-io/terraform-provider-tofusoup/tests/data_sources/test_state_resources.py`
    - **Test Structure**:
      - TestStateResourcesDataSource (6 tests) - Basic functionality
      - TestStateResourcesValidation (4 tests) - Config validation
      - TestStateResourcesRead (13 tests) - Read operations and filtering
      - TestStateResourcesErrorHandling (3 tests) - Error scenarios
      - TestStateResourcesEdgeCases (4 tests) - Edge cases
    - **Coverage**:
      - Empty states
      - States with resources
      - Filter by mode (managed, data)
      - Filter by type
      - Filter by module
      - Combined filters
      - Resource ID construction
      - Module resource IDs
      - Instance counting
      - Multi-instance detection
      - ID extraction
      - No-match filtering
      - Missing fields handling
    - **Reused Fixtures**: sample_empty_state, sample_state_with_resources, sample_state_with_modules (from conftest.py)

63. ✅ **Standalone examples created**:
    - **Directory**: `examples/data-sources/tofusoup_state_resources/`
    - **Files**:
      - `main.tf` - 6 data source configurations demonstrating all filters
      - `outputs.tf` - 10 outputs showing various use cases
      - `README.md` - Comprehensive guide with 7 use cases
    - **Example Configurations**:
      1. List all resources (no filters)
      2. Managed resources only
      3. Data sources only
      4. Specific resource type
      5. Specific module
      6. Combined filters (mode + module)
    - **Demonstrated Outputs**:
      - Resource count summaries
      - Resource type lists
      - Resource IDs
      - Instance details
      - Module grouping
      - Multi-instance detection
      - Resource types by mode
      - Provider grouping

64. ✅ **End-to-end provider testing** (terraform apply/destroy):
    - **Build**: `make build && make install` → v0.0.1108 (109.4 MB PSPF package)
    - **Terraform Init**: ✅ Successfully initialized
    - **Terraform Apply**: ✅ Success! Read and filtered resources:
      - **all_resources_summary**:
        * total_count: 6
        * managed: 4
        * data: 2
      - **resource_types**: 6 types found
        * aws_ami, aws_vpc, aws_subnet, aws_instance, aws_db_instance, aws_availability_zones
      - **managed_resource_list**: 4 resources
        * VPC, subnet, instance (in module), database (in module)
      - **instance_details**: 1 instance resource
        * instance_count: 2 (uses count/for_each)
        * has_multiple_instances: true
        * module: module.ec2_cluster
      - **ec2_managed_resources**: 1 resource
        * Successfully filtered by mode AND module
      - **module_resources**: Grouped by module
        * root: 3 resources
        * ec2_cluster: 2 resources
    - **Terraform Destroy**: ✅ Clean destroy
    - **Performance**: All 6 data sources read instantly (<1ms each)

65. ✅ **Code quality verified**:
    - All 251 tests passing (221 previous + 30 new state_resources tests)
    - Code passes `ruff format`, `ruff check --fix --unsafe-fixes`
    - Provider builds and runs successfully
    - All examples functional

66. ✅ **Key Implementation Insights**:
    - **Filter Pattern**: Sequential filtering with list comprehensions
      ```python
      if config.filter_mode:
          filtered = [r for r in filtered if r.get("mode") == config.filter_mode]
      if config.filter_type:
          filtered = [r for r in filtered if r.get("type") == config.filter_type]
      ```
    - **Instance Counting**: Simple length check
      ```python
      instances = resource.get("instances", [])
      instance_count = len(instances)
      has_multiple_instances = len(instances) > 1
      ```
    - **ID Extraction**: Safe navigation with get()
      ```python
      instance_id = None
      if instances and len(instances) > 0:
          attributes = instances[0].get("attributes", {})
          if attributes:
              instance_id = attributes.get("id")
      ```
    - **Resource ID Construction**: Conditional module inclusion
      ```python
      if module:
          resource_id = f"{mode}.{module}.{type_}.{name}"
      else:
          resource_id = f"{mode}.{type_}.{name}"
      ```
    - **No Attribute Exposure**: Decision to NOT expose full resource attributes
      * Security: Attributes may contain sensitive data
      * Size: Full attributes can be very large
      * Use case: Primary need is discovery, not full inspection
      * Alternative: Users can use `terraform state show` for details

67. ✅ **Filter Behavior**:
    - **No filters**: Returns all resources
    - **Single filter**: Returns resources matching that filter
    - **Multiple filters**: AND logic (all must match)
    - **No matches**: Returns empty list (not an error)
    - **Filter validation**: Only filter_mode validated ("managed" or "data")
    - **Type-safe filtering**: Uses .get() to handle missing fields
    - **Module filtering**: Exact match on module path

68. ✅ **Use Cases Validated**:
    1. **Resource Inventory**: List all resources with counts by type
    2. **Type Discovery**: Find all instances of specific resource type
    3. **Module Analysis**: Identify resources within modules
    4. **Mode Separation**: Separate managed resources from data sources
    5. **Count Detection**: Identify resources using count/for_each
    6. **Combined Filtering**: Find managed aws_instance in module.ec2_cluster
    7. **Migration Planning**: Analyze resource structure before migration

---

## Test Results Summary

```bash
$ PYTHONPATH=src pytest tests/data_sources/test_state_resources.py -v
======================== 30 passed, 1 warning in 0.14s ========================

$ PYTHONPATH=src pytest tests/ -v
======================== 251 passed, 1 warning in 0.83s ========================
```

---

## Real Data Verification

**Sample State File Analysis**:
```
Total Resources: 6
  - Managed: 4
  - Data: 2

Resource Types: 6
  - aws_ami (data)
  - aws_vpc (managed)
  - aws_subnet (managed)
  - aws_instance (managed, in module, 2 instances)
  - aws_db_instance (managed, in module)
  - aws_availability_zones (data, in module)

Module Distribution:
  - Root: 3 resources (ami, vpc, subnet)
  - module.ec2_cluster: 2 resources (instance, availability_zones)
  - module.database: 1 resource (db_instance)

Multi-Instance Resources: 1
  - aws_instance.web (2 instances via count/for_each)
```

**Filter Results**:
- `filter_mode="managed"`: 4 resources
- `filter_mode="data"`: 2 resources
- `filter_type="aws_instance"`: 1 resource
- `filter_module="module.ec2_cluster"`: 2 resources
- Combined (managed + ec2_cluster): 1 resource

---

## Technical Achievements

1. **Flexible Filtering System**: Three independent filters that can be combined
2. **Instance Detection**: Automatically identifies count/for_each resources
3. **Unique Resource IDs**: Constructs identifiers compatible with Terraform addressing
4. **Module Support**: Properly handles resources in nested modules
5. **Safe ID Extraction**: Extracts IDs without exposing full attributes
6. **Performance**: Efficient in-memory filtering, no external calls
7. **Test Coverage**: 30 tests covering all combinations and edge cases

---

## Comparison: state_info vs state_resources

| Aspect | state_info | state_resources |
|--------|-----------|----------------|
| **Purpose** | Aggregate statistics | Individual resource details |
| **Output** | Counts and metadata | List of resources |
| **Filtering** | None | mode, type, module |
| **Use Case** | State overview | Resource discovery |
| **Output Size** | Fixed (11 fields) | Proportional to resource count |
| **Module Info** | Count only | Per-resource module path |
| **Instance Info** | Total count | Per-resource instance count |

These two data sources are complementary:
- Use `state_info` to get high-level overview
- Use `state_resources` to get resource-level details
- Combine both for complete state analysis

---

## Design Decisions

### Why NOT Expose Full Attributes?

**Decision**: Only expose resource metadata, not full attributes

**Rationale**:
1. **Security**: Attributes often contain sensitive data (passwords, keys, endpoints)
2. **Size**: Full attributes can be hundreds of fields per resource
3. **Use Case**: Primary need is resource discovery/inventory, not full inspection
4. **Terraform Already Has This**: `terraform state show <resource>` provides full details
5. **Simplicity**: Smaller output is easier to work with in Terraform expressions

**What We DO Expose**:
- Resource identifiers (mode, type, name, module)
- Instance counts (important for count/for_each detection)
- First instance ID (most commonly needed attribute)
- Provider reference (for provider analysis)

**Future Enhancement**: Could add optional `include_attributes` flag if users need it

---

This completes the eighth data source implementation. **8 of 9 data sources now complete**. Remaining: state_outputs (read outputs from state).
