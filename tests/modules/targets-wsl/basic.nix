{ config, lib, pkgs, ... }:

{
  config = {
    targets.wsl = {
      enable = true;
      windowsTools = {
        enablePowerShell = true;
        powerShellPath = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
        enableWslPath = true;
      };
    };

    nmt.script = ''
      # Check that PowerShell and wslpath wrappers are added to extraActivationPath
      assertFileRegex activate \
        "export PATH=.*wsl-powershell-wrapper.*wsl-wslpath-wrapper.*"
        
      # Check that cmd is not enabled in basic configuration
      assertFileNotRegex activate \
        "wsl-cmd-wrapper"
        
      # Check that the WSL tools availability checks are in the activation script
      assertFileRegex activate \
        "WSL: PowerShell available in activation environment"
      assertFileRegex activate \
        "WSL: wslpath available in activation environment"
        
      # Check activation script structure
      assertFileRegex activate \
        "wslToolsCheck"
    '';
  };
}
