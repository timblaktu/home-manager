{ config, lib, pkgs, ... }:

{
  config = {
    targets.wsl = {
      enable = true;
      windowsTools = {
        enablePowerShell = false;
        enableCmd = true;
        enableWslPath = false;
      };
    };

    nmt.script = ''
      # Check that only cmd wrapper is added to extraActivationPath
      assertFileRegex activate \
        "export PATH=.*wsl-cmd-wrapper.*"
        
      # Check that PowerShell and wslpath wrappers are NOT added
      assertFileNotRegex activate \
        "wsl-powershell-wrapper"
      assertFileNotRegex activate \
        "wsl-wslpath-wrapper"
        
      # Check that only cmd availability check is present
      assertFileRegex activate \
        "WSL: cmd.exe available in activation environment"
        
      # Check that PowerShell and wslpath checks are NOT present
      assertFileNotRegex activate \
        "WSL: PowerShell available in activation environment"
      assertFileNotRegex activate \
        "WSL: wslpath available in activation environment"

    '';
  };
}
