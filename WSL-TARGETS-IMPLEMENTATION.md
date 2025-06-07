# WSL Targets Module Implementation

This document describes the complete implementation of the `targets.wsl` module for Home Manager, designed to solve PowerShell activation environment access issues and provide comprehensive WSL integration.

## Overview

The WSL targets module provides WSL-specific features for Home Manager, following the same architectural pattern as `targets.darwin`. The primary purpose is to solve the activation environment isolation issue that prevents PowerShell access during home-manager activation.

## Architecture

### Module Structure

```
modules/targets/wsl/
├── default.nix              # Main module implementation
└── tests.nix                # Test imports
```

### Core Problem Solved

**Issue**: Home Manager activation runs in a minimal, controlled environment that doesn't include Windows mount paths (`/mnt/c`) in the PATH. This prevents Windows tools like PowerShell from being accessible during activation, even though they exist on the filesystem.

**Solution**: Use `home.extraActivationPath` to add PowerShell wrapper packages to the activation environment, making Windows tools available via standard command detection.

## Implementation Details

### Options

```nix
targets.wsl = {
  enable = mkEnableOption "WSL-specific home-manager features" // {
    default = isWSL;  # Auto-detects WSL environment
  };

  windowsTools = {
    enablePowerShell = mkEnableOption "PowerShell access during activation" // {
      default = true;
    };
    
    powerShellPath = mkOption {
      type = types.str;
      default = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
      description = "Path to PowerShell executable on Windows host";
    };

    enableCmd = mkEnableOption "Windows Command Prompt access during activation";
    
    cmdPath = mkOption {
      type = types.str;
      default = "/mnt/c/Windows/System32/cmd.exe";
      description = "Path to Windows Command Prompt executable";
    };
  };
};
```

### Core Implementation

1. **WSL Detection**: Automatically detects WSL environment by checking for `/proc/sys/fs/binfmt_misc/WSLInterop`

2. **PowerShell Wrapper**: Creates a Nix package with symbolic links to Windows executables:
   ```nix
   powershellWrapper = pkgs.runCommand "wsl-powershell-wrapper" {} ''
     mkdir -p $out/bin
     ln -s ${cfg.windowsTools.powerShellPath} $out/bin/powershell.exe
   '';
   ```

3. **Activation Path Integration**: Adds wrapper to official activation environment:
   ```nix
   home.extraActivationPath = lib.optionals cfg.windowsTools.enablePowerShell [
     powershellWrapper
   ];
   ```

4. **Validation**: Activation-time check to verify Windows tools are accessible:
   ```nix
   home.activation.wslToolsCheck = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
     if command -v powershell.exe >/dev/null 2>&1; then
       verboseEcho "WSL: PowerShell available in activation environment"
     else
       echo "WARNING: PowerShell not available despite configuration"
     fi
   '';
   ```

## Usage Examples

### Basic WSL Integration

```nix
{
  targets.wsl.enable = true;  # Usually auto-detected
}
```

### Custom PowerShell Path

```nix
{
  targets.wsl = {
    enable = true;
    windowsTools = {
      enablePowerShell = true;
      powerShellPath = "/mnt/d/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
    };
  };
}
```

### Multiple Windows Tools

```nix
{
  targets.wsl = {
    enable = true;
    windowsTools = {
      enablePowerShell = true;
      enableCmd = true;
    };
  };
}
```

## Integration with Windows Symlinks

This module is designed to work seamlessly with the Windows symlinks feature:

```nix
{
  targets.wsl.enable = true;  # Provides PowerShell access
  
  home.file."example.txt" = {
    text = "Hello World";
    supportReadingFromWindows = true;  # Uses PowerShell from WSL module
  };
}
```

## Testing

### Test Structure

```
tests/modules/targets-wsl/
├── default.nix          # Test registry
└── wsl-basic.nix        # Basic functionality test
```

### Running Tests

```bash
# Navigate to home-manager directory
cd /home/tim/src/home-manager-wsl-target-module

# Run basic evaluation test
nix-instantiate --eval test-validation.nix

# Run full test suite (when available)
nix build .#checks.x86_64-linux.targets-wsl-basic
```

## Upstream Contribution Strategy

### Branch Organization

- **Current Branch**: `wsl-target-module` - WSL targets implementation
- **Separate Branch**: `windows-symlinks` - File management features
- **Reason**: Independent development and upstream contribution paths

### Contribution Benefits

1. **Fills Major Gap**: Home Manager has `targets.darwin` but no `targets.wsl`
2. **Community Impact**: Enables WSL users across the Nix ecosystem
3. **Extensible Foundation**: Framework for future WSL integrations
4. **Clean Architecture**: Follows established patterns and best practices

## Future Extensions

The WSL targets module provides a foundation for additional WSL integrations:

- **Windows clipboard integration**
- **SSH agent forwarding** 
- **Windows service integration**
- **Development tool interoperability**
- **VS Code remote development support**

## Maintenance

### Maintainers

```nix
meta.maintainers = with lib.maintainers; [ ]; # TODO: Add maintainer
```

### Documentation

- Module options automatically documented in Home Manager manual
- Examples provided in module documentation
- Integration patterns documented for other module authors

## Validation Checklist

- ✅ **Module loads correctly** in Home Manager evaluation
- ✅ **Options are accessible** and have proper types
- ✅ **extraActivationPath modified** when PowerShell enabled
- ✅ **Activation script includes validation** for Windows tools
- ✅ **Test infrastructure** follows Darwin patterns
- ✅ **Documentation complete** with usage examples
- ✅ **Integration ready** for windows-symlinks feature

## Next Steps

1. **Test in Real WSL Environment**: Validate PowerShell access during activation
2. **Integration Testing**: Combine with windows-symlinks branch
3. **End-to-End Validation**: Test Windows applications reading symlinked files
4. **Upstream Preparation**: Clean up for community contribution
5. **Documentation**: Update Home Manager manual with WSL patterns

This implementation provides the foundation for solving the PowerShell activation environment issue and enables comprehensive WSL integration for the Home Manager ecosystem.
