# HANDOFF: GitHub Actions CI/CD Setup for terraform-provider-tofusoup

## Summary

Successfully migrated and adapted GitHub Actions workflows from `terraform-provider-pyvider` to `terraform-provider-tofusoup`. The CI/CD pipeline includes build, test, and release workflows that create multi-platform provider binaries ready for Terraform Registry publication.

## Changes Completed

### 1. VERSION File
- Created `VERSION` file with initial version `0.0.1`
- Used by all workflows to determine release version

### 2. GitHub Actions Workflows

#### build-provider.yml
**Purpose:** Builds provider binaries for multiple platforms using FlavorPack

**Platforms:**
- linux_amd64 (Ubuntu 24.04)
- linux_arm64 (Ubuntu 24.04 ARM)
- darwin_amd64 (macOS 15 Intel)
- darwin_arm64 (macOS 15 ARM/Apple Silicon)

**Key Changes from pyvider:**
- All references: `terraform-provider-pyvider` → `terraform-provider-tofusoup`
- PSP package name: `terraform-provider-pyvider.psp` → `terraform-provider-tofusoup.psp`
- Binary test command: Changed from `launch-context` to `--help` (tofusoup doesn't have launch-context)
- Artifact naming updated throughout

**Trigger:** Manual dispatch via workflow_dispatch

**Artifacts:** Creates zip files for each platform with 7-day retention (configurable)

#### test-conformance.yml
**Purpose:** Runs comprehensive conformance tests on built provider binaries

**Test Platforms:**
- linux_amd64 (Ubuntu 24.04)
- darwin_arm64 (macOS 15 ARM)

**Testing Strategy (Three-Tier Approach):**

1. **Smoke Test 1:** Provider initialization (minimal config)
   - Validates provider binary loads and responds
   - Runs: `tofu init`, `tofu plan`

2. **Smoke Test 2:** Registry query test
   - Validates data source functionality
   - Uses `tofusoup_provider_info` data source to query Terraform registry
   - Runs: `tofu init`, `tofu plan`, `tofu apply`, `tofu output`

3. **Single Test Verification:** Full lifecycle test (NEW)
   - Acts as circuit breaker before full suite
   - Tests `tofusoup_provider_versions` example
   - Runs complete cycle: `tofu init` → `tofu plan` → `tofu apply` → `tofu destroy`
   - If this fails, full conformance suite is skipped
   - Uses `TF_LOG=DEBUG` and `PYVIDER_LOG_LEVEL=debug` for detailed logging

4. **Full Conformance Suite:** All examples
   - Runs `soup stir --recursive` on all 9 data source examples in `examples/data-sources/`
   - Multi-threaded execution for performance
   - Captures and parses output for intelligent error reporting
   - Uses `TF_LOG=DEBUG` and `PYVIDER_LOG_LEVEL=debug`

**Failure Handling (Hybrid Approach):**
- **Platform Independence:** `fail-fast: false` - both platforms complete independently
- **Circuit Breaker:** Single test acts as gate - full suite only runs if single test passes
- **Failure Collection:** `continue-on-error: true` on full suite - collects all failures instead of stopping at first
- **Intelligent Reporting:** Parses soup stir output to extract failure summaries and error details

**Error Reporting Features:**
- Captures soup stir output to `/tmp/conformance_output.txt`
- Parses results to show pass/fail counts
- Extracts failure details and error messages
- Creates detailed job summary with:
  - Results table by platform
  - Test coverage breakdown
  - Failure analysis with next steps
  - Links to artifacts for detailed logs

**Artifacts Uploaded (7-day retention):**
- `conformance_output.txt` - Full soup stir output with error analysis
- `.soup/logs/` - Individual test logs for each example
- `terraform.log` - Detailed Terraform execution logs
- `terraform.tfstate*` - State files from failed tests
- `.terraform.lock.hcl` - Lock files for debugging
- `crash.log` - Terraform crash logs if any

**Major Changes from pyvider:**
- Removed all PYVIDER_TESTMODE and PYVIDER_PRIVATE_STATE_SHARED_SECRET environment variables
- Provider source: `local/providers/pyvider` → `local/providers/tofusoup`
- Added single test verification step as circuit breaker
- Added hybrid failure handling for better error visibility
- Added intelligent error reporting and parsing
- Enhanced artifacts to include conformance output and crash logs

**Trigger:**
- Automatically after build workflow completes
- Manual dispatch with build_run_id parameter

#### release.yml
**Purpose:** Creates GitHub releases with signed artifacts ready for Terraform Registry

**Features:**
- Optionally triggers new build or uses existing build artifacts
- Generates documentation using Plating (`make docs`)
- Commits documentation with providebot
- Downloads build artifacts
- Generates SHA256 checksums
- Signs checksums with GPG (or creates placeholders if secrets missing)
- Creates GitHub release with all artifacts

**Key Changes from pyvider:**
- All references: `pyvider` → `tofusoup`
- Provider namespace: `provide-io/pyvider` → `provide-io/tofusoup`
- Release notes updated for TofuSoup description
- Documentation generation uses `make docs` instead of custom script

**Trigger:** Manual dispatch via workflow_dispatch

**Inputs:**
- `prerelease`: Boolean (default: false)
- `generate_docs`: Boolean (default: true)
- `build_run_id`: Optional string (leave empty to trigger new build)

### 3. Supporting Scripts

#### .github/scripts/sign-release.sh
**Purpose:** GPG signing for release artifacts

**Key Feature - Graceful Degradation:**
- If GPG secrets are missing, creates placeholder `.sig` files with message:
  ```
  NOT_SIGNED - GPG_PRIVATE_KEY and/or GPG_KEY_ID environment variables not set
  ```
- This allows releases to be created for testing without failing on missing secrets
- Warns users that signatures are placeholders only

**No provider-specific changes needed**

#### .github/scripts/install-provider.sh
**Purpose:** Installs provider binary to local Terraform plugin directory

**Changes:**
- Plugin directory: `~/.terraform.d/plugins/local/providers/pyvider` → `~/.terraform.d/plugins/local/providers/tofusoup`
- Binary name: `terraform-provider-pyvider` → `terraform-provider-tofusoup`

**Usage:**
```bash
./install-provider.sh <version> <platform> <source_binary>
```

### 4. Terraform Registry Manifest
- Created `terraform-registry-manifest.json` (generic, no provider-specific changes)
- Declares protocol version 6.0

## Required GitHub Secrets

**CRITICAL:** The following secrets must be configured for full functionality:

### Bot Authentication (Required for docs commit and release)
- `PROVIDE_BOT_APP_ID` - GitHub App ID for providebot
- `PROVIDE_BOT_PRIVATE_KEY` - GitHub App private key for providebot

### GPG Signing (Optional - graceful degradation)
- `GPG_PRIVATE_KEY` - GPG private key for signing releases
- `GPG_PASSPHRASE` - Passphrase for GPG key
- `GPG_KEY_ID` - GPG key ID

**Note:** If GPG secrets are not configured, the release workflow will create placeholder signature files and continue. This allows testing the release process without real signatures.

### How to Configure Secrets

#### Organization Level (Recommended)
If secrets are already configured at the `provide-io` organization level, they will be available to this repository automatically.

#### Repository Level
1. Go to repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add each secret with its value

## Testing the Workflows

### Step 1: Manual Build Test
```bash
# Navigate to Actions tab on GitHub
# Select "🏗️ Build Provider Binary" workflow
# Click "Run workflow"
# Leave retention days at 7 (default)
# Click "Run workflow" button
```

**Expected Result:**
- Build completes successfully for all 4 platforms
- Artifacts are uploaded (4 zip files)
- Conformance tests automatically trigger

### Step 2: Verify Conformance Tests
**Expected Result:**
- Tests run on linux_amd64 and darwin_arm64
- Smoke Test 1: Provider initialization succeeds
- Smoke Test 2: Registry query succeeds (queries hashicorp/aws from Terraform registry)
- Full conformance suite runs on all examples in `examples/data-sources/`

**Potential Issues:**
1. **Missing Examples:** If any data source lacks an example, conformance tests will fail
2. **API Rate Limiting:** Registry queries might fail if rate limited
3. **Network Issues:** Tests require internet access to query registries

### Step 3: Manual Release Test (Optional)
```bash
# Navigate to Actions tab on GitHub
# Select "🚀 Release Provider" workflow
# Click "Run workflow"
# Set inputs:
#   - prerelease: false
#   - generate_docs: true
#   - build_run_id: (leave empty to trigger new build)
# Click "Run workflow" button
```

**Expected Result:**
- If build_run_id is empty: New build is triggered and waits for completion
- Documentation is generated and committed
- All artifacts are downloaded and organized
- SHA256SUMS file is created
- Checksums are signed (or placeholder created if GPG secrets missing)
- GitHub release is created with tag `v0.0.1`
- All artifacts are attached to release

**Potential Issues:**
1. **Missing Bot Secrets:** If PROVIDE_BOT secrets are missing, docs commit will fail
2. **GPG Secrets Missing:** Release will still succeed but with placeholder signatures (warning displayed)
3. **First Release:** May need to ensure no existing `v0.0.1` tag/release

## Workflow Dependencies

```
build-provider.yml
    ↓ (auto-triggers)
test-conformance.yml
    ↓ (manual trigger)
release.yml
    ↓ (optionally triggers)
build-provider.yml (if build_run_id not provided)
```

## File Structure Created

```
terraform-provider-tofusoup/
├── VERSION                                 # Version file (0.0.1)
├── terraform-registry-manifest.json        # Registry metadata
├── .github/
│   ├── workflows/
│   │   ├── build-provider.yml             # Build workflow
│   │   ├── test-conformance.yml           # Test workflow
│   │   └── release.yml                    # Release workflow
│   └── scripts/
│       ├── sign-release.sh                # GPG signing (with graceful degradation)
│       └── install-provider.sh            # Local provider installation
└── .provide/
    └── HANDOFF.md                         # This document
```

## Next Steps

### Immediate (Before First Release)
1. **Configure GitHub Secrets** (if not already at org level):
   - PROVIDE_BOT_APP_ID
   - PROVIDE_BOT_PRIVATE_KEY
   - GPG_PRIVATE_KEY
   - GPG_PASSPHRASE
   - GPG_KEY_ID

2. **Verify Examples:** Ensure all data sources have examples in `examples/data-sources/`:
   - tofusoup_provider_info
   - tofusoup_provider_versions
   - tofusoup_module_info
   - tofusoup_module_versions
   - tofusoup_module_search
   - tofusoup_registry_search
   - tofusoup_state_info
   - tofusoup_state_resources
   - tofusoup_state_outputs

3. **Test Build Workflow:**
   - Run manually from Actions tab
   - Verify all 4 platforms build successfully
   - Check artifact uploads

4. **Test Conformance Workflow:**
   - Should auto-trigger after build
   - Verify smoke tests pass
   - Verify full conformance suite passes

### Optional (For Production Releases)
5. **Configure GPG Signing:**
   - Generate or import GPG key
   - Add secrets to GitHub
   - Re-run release workflow to test real signatures

6. **Update VERSION File:**
   - For production releases, increment version
   - Commit change before triggering release workflow

7. **Publish to Terraform Registry:**
   - Follow Terraform Registry provider publishing guidelines
   - Use signed artifacts from GitHub release

## Troubleshooting

### Build Fails with PyPI Issues
**Symptom:** Build step fails with dependency resolution errors

**Solution:**
- Workflow includes retry logic with 30s delay
- Check `uv` and `pip` cache clearing steps
- Verify `pyproject.toml` dependencies are valid

### Conformance Tests Fail on Smoke Test 2
**Symptom:** Registry query test fails

**Possible Causes:**
1. Network/internet access blocked on runner
2. API rate limiting from Terraform registry
3. Provider not correctly installed to plugin directory
4. Data source implementation issue

**Solution:**
- Check test logs in workflow run
- Verify provider binary is executable
- Test locally with same Terraform config

### Release Fails on Documentation Generation
**Symptom:** Release workflow fails during documentation generation

**Possible Causes:**
1. `make docs` command fails
2. Missing dependencies for Plating
3. Invalid docstrings in component code

**Solution:**
- Test `make docs` locally first
- Review component docstrings format
- Check Plating requirements in `pyproject.toml`

### Release Succeeds but Signatures are Placeholders
**Symptom:** Release completes but `.sig` files contain "NOT_SIGNED" message

**Cause:** GPG secrets not configured

**Solution:**
- This is expected behavior when secrets are missing
- Configure GPG_PRIVATE_KEY, GPG_PASSPHRASE, GPG_KEY_ID secrets
- Re-run release workflow
- For production releases, proper GPG signatures are required for Terraform Registry

### Conformance Tests Skip Examples
**Symptom:** Some data sources are not tested

**Cause:** Missing example directories or invalid Terraform configs

**Solution:**
- Ensure every data source has an example in `examples/data-sources/<datasource_name>/`
- Each example must have valid `main.tf` (minimum)
- Test examples locally with `soup stir`

## Additional Notes

### Platform Selection
- **Build:** All 4 platforms to ensure broad compatibility
- **Test:** Only 2 platforms (linux_amd64, darwin_arm64) to save CI resources
- Representative platforms chosen for testing

### Artifact Retention
- Default: 7 days for build artifacts
- Can be overridden via workflow input
- Release artifacts are permanent (stored in GitHub releases)

### Version Management
- Version is read from `VERSION` file (not `pyproject.toml`)
- Must be updated manually before releases
- Consider semantic versioning (MAJOR.MINOR.PATCH)

### Documentation Generation
- Uses Plating to generate docs from code docstrings
- Committed automatically by providebot
- Ensure all components have comprehensive docstrings

## Success Criteria

✅ **Build Workflow:**
- All 4 platform builds complete successfully
- PSP packages are created and tested
- Zip archives are properly formatted
- Artifacts are uploaded

✅ **Conformance Workflow:**
- Provider binary verifies successfully
- Provider installs to plugin directory
- Smoke Test 1 (initialization) passes
- Smoke Test 2 (registry query) passes
- Full conformance suite runs on all examples
- Test logs are uploaded

✅ **Release Workflow:**
- Build completes (triggered or reused)
- Documentation generates and commits
- All artifacts are organized
- Checksums are generated
- Signatures are created (real or placeholder)
- GitHub release is published with all assets
- Release notes are properly formatted

## References

- **Source Repository:** `terraform-provider-pyvider` (GitHub Actions reference implementation)
- **Pyvider Framework:** https://github.com/provide-io/pyvider
- **TofuSoup CLI:** https://github.com/provide-io/tofusoup
- **FlavorPack:** https://github.com/provide-io/flavorpack
- **Plating:** https://github.com/provide-io/plating
- **Terraform Registry Provider Publishing:** https://www.terraform.io/docs/registry/providers/publishing.html

---

**Document Created:** 2025-11-11
**Changes Pushed:** Commit bf5bb46
**Initial Version:** 0.0.1
**Status:** Ready for testing
