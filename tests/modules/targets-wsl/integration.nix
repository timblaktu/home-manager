{ config, lib, pkgs, ... }:

{
  config = {
    targets.wsl = {
      enable = true;
      windowsTools = {
        enablePowerShell = true;
        enableCmd = true;
        enableWslPath = true;
      };
    };

    nmt.script = ''
      # Integration test: verify all tools work together
      assertFileRegex activate \
        "wsl-powershell-wrapper.*wsl-cmd-wrapper.*wsl-wslpath-wrapper"

      assertFileRegex activate \
        "WSL: PowerShell available in activation environment"
      assertFileRegex activate \
        "WSL: cmd.exe available in activation environment"
      assertFileRegex activate \
        "WSL: wslpath available in activation environment"
    '';
  };
}
