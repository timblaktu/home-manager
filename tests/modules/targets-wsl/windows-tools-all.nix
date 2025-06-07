{ config, lib, pkgs, ... }:

{
  config = {
    targets.wsl = {
      enable = true;
      windowsTools = {
        enablePowerShell = true;
        powerShellPath = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
        enableCmd = true;
        cmdPath = "/mnt/c/Windows/System32/cmd.exe";
        enableWslPath = true;
        wslPathPath = "/usr/bin/wslpath";
      };
    };

    nmt.script = ''
      # Check that all tools (with extension-less aliases) are added to extraActivationPath
      assertFileRegex activate \
        "export PATH=.*powershell.exe.*powershell.*cmd.exe.*cmd.*wslpath.*"
        
      # Check individual tool availability checks in activation script
      assertFileRegex activate \
        "WSL: PowerShell available in activation environment"
      assertFileRegex activate \
        "WSL: cmd.exe available in activation environment"
      assertFileRegex activate \
        "WSL: wslpath available in activation environment"
        
      # Verify custom paths are used in tool executables
      assertFileRegex activate \
        "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
      assertFileRegex activate \
        "/mnt/c/Windows/System32/cmd.exe"
      assertFileRegex activate \
        "/usr/bin/wslpath"
    '';
  };
}
