# WSL Target Module Test Suite

This document describes the comprehensive test suite for the `targets.wsl` Home Manager module.

## Test Structure

The test suite follows Home Manager's standard testing patterns using the `nmt` (Nix Module Tests) framework. Tests validate both configuration evaluation and activation script generation.

## Test Files

### `wsl-basic.nix`
**Purpose**: Basic functionality test with PowerShell and wslpath enabled  
**Coverage**:
- PowerShell wrapper creation and PATH integration
- wslpath wrapper creation and PATH integration
- Custom PowerShell path configuration
- Activation script structure validation
- Tool availability checks

### `wsl-defaults.nix`
**Purpose**: Validates default behavior when minimal configuration is provided  
**Coverage**:
- Default tool enabling (PowerShell + wslpath enabled, cmd disabled)
- Default path usage
- Correct activation script generation for defaults
- Verification that disabled tools don't appear

### `wsl-windows-tools-all.nix`
**Purpose**: Tests all Windows tools enabled with custom paths  
**Coverage**:
- PowerShell, cmd, and wslpath all enabled simultaneously
- Custom path configuration for all tools
- All tool wrappers in activation PATH
- All tool availability checks present
- Custom path usage validation

### `wsl-selective-tools.nix`
**Purpose**: Tests selective enabling/disabling of tools  
**Coverage**:
- PowerShell disabled, cmd enabled, wslpath disabled
- Only enabled tools appear in activation PATH
- Conditional activation script generation
- Disabled tool validation

### `wsl-disabled.nix`
**Purpose**: Tests complete WSL target module disabling  
**Coverage**:
- No WSL tool wrappers when module disabled
- No WSL-related activation script entries
- Clean activation script without WSL components

### `wsl-wslpath-only.nix`
**Purpose**: Tests minimal configuration with only wslpath enabled  
**Coverage**:
- wslpath-only configuration (important for integration scenarios)
- Custom wslpath path configuration
- Other tools explicitly disabled
- Minimal activation script footprint

## Running Tests

### Quick Validation
```bash
./test-quick.sh
```
Runs basic evaluation and build tests to catch major issues quickly.

### Comprehensive Test Suite
```bash
./test-comprehensive.sh
```
Runs all test cases with detailed reporting and coverage analysis.

### Individual Test Cases
```bash
# Run specific test
nix build .#checks.x86_64-linux.tests.modules.targets-wsl.wsl-basic

# Debug test failures
nix build .#checks.x86_64-linux.tests.modules.targets-wsl.wsl-defaults --show-trace
```

## Test Validation Methods

### `assertFileRegex activate <pattern>`
Validates that the activation script contains the specified pattern. Used for:
- PATH modification verification
- Tool availability check presence
- Custom path usage validation
- Activation script structure

### `assertFileNotRegex activate <pattern>`
Validates that the activation script does NOT contain the pattern. Used for:
- Disabled tool verification
- Selective configuration validation
- Clean script generation

## Test Coverage Matrix

| Test Case | PowerShell | cmd.exe | wslpath | Custom Paths | Notes |
|-----------|------------|---------|---------|--------------|--------|
| basic | ✓ | ✗ | ✓ | ✓ (PS) | Standard use case |
| defaults | ✓ | ✗ | ✓ | ✗ | Default behavior |
| all-tools | ✓ | ✓ | ✓ | ✓ (all) | Maximum configuration |
| selective | ✗ | ✓ | ✗ | ✗ | Selective enabling |
| disabled | ✗ | ✗ | ✗ | ✗ | Module disabled |
| wslpath-only | ✗ | ✗ | ✓ | ✓ (wslpath) | Minimal for integration |

## Integration Test Strategy

These tests validate the WSL target module in isolation. For integration with the Windows shortcuts feature:

1. **Phase 1**: Run these tests to validate WSL target module
2. **Phase 2**: Integration tests in windows-symlinks repository
3. **Phase 3**: End-to-end tests with actual file operations

## Expected Test Results

All tests should pass before committing changes to the WSL target module. The test suite validates:

- ✅ Configuration evaluation without errors
- ✅ Proper activation script generation
- ✅ Correct PATH modification
- ✅ Tool wrapper creation
- ✅ Conditional logic for enabled/disabled tools
- ✅ Custom path handling
- ✅ Default behavior compliance

## Troubleshooting

### Common Test Failures

**Evaluation Errors**: Usually indicate syntax or type errors in the module  
**Build Failures**: Often related to missing dependencies or path issues  
**Regex Failures**: Indicate activation script generation problems

### Debug Commands

```bash
# Check module evaluation
nix-instantiate --eval test-validation.nix

# Check activation script content
nix build .#checks.x86_64-linux.tests.modules.targets-wsl.wsl-basic
cat result/activate

# Show detailed build information
nix build .#checks.x86_64-linux.tests.modules.targets-wsl.wsl-basic --show-trace -v
```

This comprehensive test suite ensures the WSL target module functions correctly across all supported configurations before integration with dependent features.
