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
      # Check that PowerShell (both .exe and extension-less) and wslpath are added to extraActivationPath
      assertFileRegex activate \
        "export PATH=.*powershell.exe.*powershell.*wslpath.*"
        
      # Check that cmd is not enabled in basic configuration
      assertFileNotRegex activate \
        "cmd.exe"
      assertFileNotRegex activate \
        "[^.]cmd[^.]"
        
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
