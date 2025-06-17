# WSL Target Module for Home Manager
#
# This module provides Windows Subsystem for Linux (WSL) integration capabilities
# for Home Manager configurations. It enables seamless interaction between WSL
# Linux environments and the Windows host system.
#
# Features:
# - Automatic Windows environment variable detection
# - Explicit Windows username configuration for pure builds
# - Windows tool wrappers (PowerShell, cmd.exe, wslpath)
# - Windows path generation and conversion utilities
# - Integration with Windows filesystem through standard mount points
#
# Usage Examples:
#
# Basic WSL integration:
#   targets.wsl.enable = true;
#
# Explicit username (for pure configurations):
#   targets.wsl = {
#     enable = true;
#     windowsUsername = "myuser";
#   };
#
# Full configuration with Windows tools:
#   targets.wsl = {
#     enable = true;
#     windowsUsername = "myuser";
#     windowsTools = {
#       enablePowerShell = true;
#       enableWslPath = true;
#     };
#   };
#
# Accessing computed values in other modules:
#   config.targets.wsl.windowsUsernameFinal  # Final username
#   config.targets.wsl.windowsHomeDir        # /mnt/c/Users/<username>
#   config.targets.wsl.wslDistroName         # Current distro name
#
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.targets.wsl;

  # Create source files containing Windows environment variables
  # This avoids impureEnvVars issues by treating variables as source inputs
  windowsEnvSrc = pkgs.runCommand "windows-env-src" {} ''
    mkdir -p $out
    echo "${builtins.getEnv "USERNAME"}" > $out/USERNAME
    echo "${builtins.getEnv "USERPROFILE"}" > $out/USERPROFILE
    echo "${builtins.getEnv "WSL_DISTRO_NAME"}" > $out/WSL_DISTRO_NAME
  '';

  # Normal derivation using the source files as input
  windowsEnvironment = pkgs.runCommand "windows-environment-vars" {
    src = windowsEnvSrc;

      meta.description = "Windows environment variables for WSL integration";
    } ''
      # Copy source files to output with safe fallbacks
      mkdir -p $out
      
      # Read captured values from source with fallbacks
      USERNAME="$(cat $src/USERNAME)"
      USERPROFILE="$(cat $src/USERPROFILE)"
      WSL_DISTRO_NAME="$(cat $src/WSL_DISTRO_NAME)"
      
      echo "''${USERNAME:-unknown}" > $out/USERNAME
      echo "''${USERPROFILE:-/mnt/c/Users/unknown}" > $out/USERPROFILE
      echo "''${WSL_DISTRO_NAME:-NixOS}" > $out/WSL_DISTRO_NAME

      # Debug information
      cat > $out/DEBUG << 'EOF'
=== BUILD ENVIRONMENT DEBUG ===
Read from source files:
EOF
      echo "USERNAME: [$USERNAME]" >> $out/DEBUG
      echo "USERPROFILE: [$USERPROFILE]" >> $out/DEBUG  
      echo "WSL_DISTRO_NAME: [$WSL_DISTRO_NAME]" >> $out/DEBUG

      # Summary
      cat > $out/SUMMARY << 'EOF'
Captured Windows environment variables:
EOF
      echo "USERNAME: ''${USERNAME:-unknown}" >> $out/SUMMARY
      echo "USERPROFILE: ''${USERPROFILE:-/mnt/c/Users/unknown}" >> $out/SUMMARY
      echo "WSL_DISTRO_NAME: ''${WSL_DISTRO_NAME:-NixOS}" >> $out/SUMMARY
    '';


in

{
  meta.maintainers = with maintainers; [ ];

  options.targets.wsl = {
    enable = mkEnableOption "WSL (Windows Subsystem for Linux) compatibility tweaks";

    windowsEnvironment = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        Fixed-output derivation containing Windows environment variables captured at build time.
        Files in this derivation correspond to environment variable names.
        Uses impureEnvVars to safely capture USERNAME, USERPROFILE, and WSL_DISTRO_NAME.
      '';
    };

    windowsUsername = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "tblack";
      description = ''
        Windows username. If null, will be captured from the USERNAME environment variable.
        Set this explicitly for pure configurations without --impure flag.
      '';
    };

    windowsUsernameFinal = mkOption {
      type = types.str;
      readOnly = true;
      description = ''
        Final computed Windows username, either from explicit setting or environment capture.
      '';
    };

    windowsHomeDir = mkOption {
      type = types.str;
      readOnly = true;
      description = ''
        Windows user home directory captured from the USERPROFILE environment variable.
        Falls back to /mnt/c/Users/USERNAME if not available.
      '';
    };

    wslDistroName = mkOption {
      type = types.str;
      readOnly = true;
      description = ''
        WSL distribution name captured from the WSL_DISTRO_NAME environment variable.
        Falls back to "NixOS" if not available.
      '';
    };

    wslToWindowsUNC = mkOption {
      type = types.functionTo types.str;
      readOnly = true;
      description = ''
        Helper function to convert WSL paths to Windows UNC paths.
        Example: wslToWindowsUNC "/home/tim" -> "\\wsl.localhost\NixOS\home\tim"
      '';
    };

    windowsTools = {
      enablePowerShell = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable PowerShell wrapper in the activation environment.
        '';
      };

      powerShellPath = mkOption {
        type = types.str;
        default = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
        description = ''
          Path to PowerShell executable on the Windows host.
        '';
      };

      enableCmd = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable cmd.exe wrapper in the activation environment.
        '';
      };

      cmdPath = mkOption {
        type = types.str;
        default = "/mnt/c/Windows/System32/cmd.exe";
        description = ''
          Path to cmd.exe executable on the Windows host.
        '';
      };

      enableWslPath = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable wslpath wrapper in the activation environment.
        '';
      };

      wslPathPath = mkOption {
        type = types.str;
        default = "/usr/bin/wslpath";
        description = ''
          Path to wslpath executable.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      windowsEnvironment
      pkgs.wslu
      pkgs.dos2unix
      pkgs.usbutils
    ];

    # Expose the Windows environment variables as config options with safe fallbacks
    targets.wsl.windowsEnvironment = windowsEnvironment;
    targets.wsl.windowsUsernameFinal = 
      if cfg.windowsUsername != null 
      then cfg.windowsUsername
      else lib.removeSuffix "\n" (builtins.readFile "${windowsEnvironment}/USERNAME");
    targets.wsl.windowsHomeDir = 
      if cfg.windowsUsername != null 
      then "/mnt/c/Users/${cfg.windowsUsername}"
      else lib.removeSuffix "\n" (builtins.readFile "${windowsEnvironment}/USERPROFILE");
    targets.wsl.wslDistroName = lib.removeSuffix "\n" (builtins.readFile "${windowsEnvironment}/WSL_DISTRO_NAME");
    targets.wsl.wslToWindowsUNC = wslPath: "\\\\wsl.localhost\\${cfg.wslDistroName}${wslPath}";

    home.extraActivationPath =
      let
        # Create wrapper with the natural tool name and optional extension-less alias
        # This provides both powershell.exe/powershell, cmd.exe/cmd for better UX
        wrapperFor = toolName: path: extensionlessAlias:
          let
            mainWrapper = pkgs.writeShellScriptBin toolName ''
              exec "${path}" "$@"
            '';
            aliasWrapper = if extensionlessAlias != null then
              pkgs.writeShellScriptBin extensionlessAlias ''
                exec "${path}" "$@"
              ''
            else null;
          in
          [ mainWrapper ] ++ (if aliasWrapper != null then [ aliasWrapper ] else []);

        toolWrappers = lib.flatten ([ ]
          ++ optional cfg.windowsTools.enablePowerShell (wrapperFor "powershell.exe" cfg.windowsTools.powerShellPath "powershell")
          ++ optional cfg.windowsTools.enableCmd (wrapperFor "cmd.exe" cfg.windowsTools.cmdPath "cmd")
          ++ optional cfg.windowsTools.enableWslPath (wrapperFor "wslpath" cfg.windowsTools.wslPathPath null));

      in
      toolWrappers;

    home.activation.wslToolsCheck = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # WSL tools availability checks
      ${optionalString cfg.windowsTools.enablePowerShell ''
        if [[ -x "${cfg.windowsTools.powerShellPath}" ]]; then
          verboseEcho "WSL: PowerShell available in activation environment"
        else
          echo "WSL: Warning - PowerShell not found at ${cfg.windowsTools.powerShellPath}"
        fi
      ''}

      ${optionalString cfg.windowsTools.enableCmd ''
        if [[ -x "${cfg.windowsTools.cmdPath}" ]]; then
          verboseEcho "WSL: cmd.exe available in activation environment"
        else
          echo "WSL: Warning - cmd.exe not found at ${cfg.windowsTools.cmdPath}"
        fi
      ''}

      ${optionalString cfg.windowsTools.enableWslPath ''
        if [[ -x "${cfg.windowsTools.wslPathPath}" ]]; then
          verboseEcho "WSL: wslpath available in activation environment"
        else
          echo "WSL: Warning - wslpath not found at ${cfg.windowsTools.wslPathPath}"
        fi
      ''}

      # End WSL tools check
    '';
  };
}
