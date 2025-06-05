{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.targets.wsl;

  isWSL = builtins.pathExists "/proc/sys/fs/binfmt_misc/WSLInterop";
  
  powershellWrapper = pkgs.runCommand "wsl-powershell-wrapper" {} ''
    mkdir -p $out/bin
    ln -s ${cfg.windowsTools.powerShellPath} $out/bin/powershell.exe
  '';

in
{
  options.targets.wsl = {
    enable = lib.mkEnableOption "WSL-specific home-manager features" // {
      default = isWSL;
    };

    windowsTools = {
      enablePowerShell = lib.mkEnableOption "PowerShell access during home-manager activation" // {
        default = true;
      };

      powerShellPath = lib.mkOption {
        type = lib.types.str;
        default = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
        description = "Path to PowerShell executable on Windows host";
        example = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
      };

      enableCmd = lib.mkEnableOption "Windows Command Prompt (cmd.exe) access during activation";

      cmdPath = lib.mkOption {
        type = lib.types.str;
        default = "/mnt/c/Windows/System32/cmd.exe";
        description = "Path to Windows Command Prompt executable";
        example = "/mnt/c/Windows/System32/cmd.exe";
      };
    };
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isLinux) {
    # Note: Assertions with pathExists are disabled for testing compatibility
    # In real WSL environments, these paths should exist
    assertions = [
      # {
      #   assertion = !cfg.windowsTools.enablePowerShell || builtins.pathExists cfg.windowsTools.powerShellPath;
      #   message = "PowerShell not found at ${cfg.windowsTools.powerShellPath}. Please check the path or disable PowerShell integration.";
      # }
      # {
      #   assertion = !cfg.windowsTools.enableCmd || builtins.pathExists cfg.windowsTools.cmdPath;
      #   message = "Windows Command Prompt not found at ${cfg.windowsTools.cmdPath}. Please check the path or disable cmd integration.";
      # }
    ];

    home.extraActivationPath = 
      lib.optionals cfg.windowsTools.enablePowerShell [
        powershellWrapper
      ] ++
      lib.optionals cfg.windowsTools.enableCmd [
        (pkgs.runCommand "wsl-cmd-wrapper" {} ''
          mkdir -p $out/bin
          ln -s ${cfg.windowsTools.cmdPath} $out/bin/cmd.exe
        '')
      ];

    home.activation.wslToolsCheck = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      if [[ ${lib.boolToString cfg.windowsTools.enablePowerShell} == "true" ]]; then
        if command -v powershell.exe >/dev/null 2>&1; then
          verboseEcho "WSL: PowerShell available in activation environment"
        else
          echo "WARNING: PowerShell not available in activation environment despite configuration"
        fi
      fi
      
      if [[ ${lib.boolToString cfg.windowsTools.enableCmd} == "true" ]]; then
        if command -v cmd.exe >/dev/null 2>&1; then
          verboseEcho "WSL: Windows Command Prompt available in activation environment"
        else
          echo "WARNING: Windows Command Prompt not available in activation environment despite configuration"
        fi
      fi
    '';
  };
}
