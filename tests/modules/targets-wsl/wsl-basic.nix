{
  config = {
    targets.wsl = {
      enable = true;
      windowsTools = {
        enablePowerShell = true;
        powerShellPath = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
      };
    };

    nmt.script = ''
      # Check that the PowerShell wrapper is added to extraActivationPath
      assertFileRegex activate \
        "export PATH=.*powershell.exe.*"
        
      # Check that the WSL tools check is in the activation script
      assertFileRegex activate \
        "WSL: PowerShell available in activation environment"
    '';
  };
}
