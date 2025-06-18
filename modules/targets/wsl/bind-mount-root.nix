{ config, lib, pkgs, wslHostname ? "unknown", ... }:

with lib;

let
  cfg = config.targets.wsl.bindMountRoot;
  
  # Use hostname from specialArgs for mountpoint
  actualMountpoint = if cfg.mountpoint == "/mnt/wsl/\${HOSTNAME}" 
    then "/mnt/wsl/${wslHostname}"
    else cfg.mountpoint;
  
  # Commands to show user
  mountCommand = "sudo mount --bind / ${actualMountpoint}/ -o x-mount.mkdir";
  bootCommand = "mount --bind / ${actualMountpoint}/ -o x-mount.mkdir";

in

{
  options.targets.wsl.bindMountRoot = {
    enable = mkEnableOption "WSL cross-instance root filesystem bind mount for non-NixOS systems";
    
    mountpoint = mkOption {
      type = types.str;
      default = "/mnt/wsl/\${HOSTNAME}";
      description = ''
        Mount point for the root filesystem bind mount.
        
        This module is designed for non-NixOS systems only.
        For NixOS systems, use the wsl.crossInstanceMount option from NixOS-WSL.
        
        The module provides instructions for manual setup since home-manager
        cannot modify system files or execute privileged commands.
      '';
    };
  };

  config = mkIf cfg.enable {
    warnings = [
      ''
        targets.wsl.bindMountRoot: WSL cross-instance mount configuration required
        
        MANUAL SETUP REQUIRED:
        
        1. Create the mount immediately:
           ${mountCommand}
        
        2. Add to /etc/wsl.conf for persistence across WSL restarts:
           
           [boot]
           systemd = true
           command = "${bootCommand}"
           
           [automount]
           enabled = true
        
        Target mount point: ${actualMountpoint}
        
        Note: For NixOS systems, use wsl.crossInstanceMount from NixOS-WSL instead.
      ''
    ];
    
    # Set environment variable for scripts that need the mount path
    home.sessionVariables = {
      WSL_CROSS_INSTANCE_MOUNT = actualMountpoint;
    };
    
    # Create a convenience script for the mount command
    home.packages = with pkgs; [
      (writeShellScriptBin "wsl-setup-cross-mount" ''
        echo "Setting up WSL cross-instance mount at ${actualMountpoint}"
        echo "Running: ${mountCommand}"
        ${mountCommand}
        echo "Mount created. Add the following to /etc/wsl.conf [boot] section:"
        echo "command = \"${bootCommand}\""
      '')
    ];
  };
}
