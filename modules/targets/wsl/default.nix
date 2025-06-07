{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.targets.wsl;

in

{
  meta.maintainers = with maintainers; [ ];

  options.targets.wsl = {
    enable = mkEnableOption "WSL (Windows Subsystem for Linux) compatibility tweaks";

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
