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
      # Integration test: verify all tools (with aliases) work together
      assertFileRegex activate \
        "powershell.exe.*powershell.*cmd.exe.*cmd.*wslpath"

      assertFileRegex activate \
        "WSL: PowerShell available in activation environment"
      assertFileRegex activate \
        "WSL: cmd.exe available in activation environment"
      assertFileRegex activate \
        "WSL: wslpath available in activation environment"
    '';
  };
}
