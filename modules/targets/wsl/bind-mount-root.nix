{ config, lib, ... }:

with lib;

{
  options.targets.wsl.bindMountRoot = {
    enable = mkEnableOption "WSL cross-instance root filesystem bind mount";
    
    mountpoint = mkOption {
      type = types.str;
      default = "/mnt/wsl/\${WSL_DISTRO_NAME}";
      description = ''
        Mount point for the root filesystem bind mount.
        
        References:
        - https://learn.microsoft.com/en-us/windows/wsl/wsl-config#automount-settings
        - https://learn.microsoft.com/en-us/windows/wsl/wsl2-mount-disk#access-the-disk-content
      '';
    };
  };

  config = mkIf config.targets.wsl.bindMountRoot.enable {
    fileSystems."${config.targets.wsl.bindMountRoot.mountpoint}" = {
      device = "/";
      options = [ "bind" "x-mount.mkdir" ];
    };
  };
}
