{ config, lib, pkgs, ... }:

{
  config = {
    targets.wsl = {
      enable = true;
      windowsTools = {
        enablePowerShell = false;
        enableCmd = false;
        enableWslPath = true;
        wslPathPath = "/custom/path/to/wslpath";
      };
    };

    nmt.script = ''
      # Check that only wslpath is added to extraActivationPath
      assertFileRegex activate \
        "export PATH=.*wslpath.*"
        
      # Check that PowerShell and cmd are NOT added
      assertFileNotRegex activate \
        "powershell.exe"
      assertFileNotRegex activate \
        "cmd.exe"
        
      # Check that custom wslpath path is used
      assertFileRegex activate \
        "/custom/path/to/wslpath"
        
      # Check that only wslpath availability check is enabled
      assertFileRegex activate \
        "WSL: wslpath available in activation environment"
        
      # Check that other tool messages are NOT present
      assertFileNotRegex activate \
        "WSL: PowerShell available in activation environment"
      assertFileNotRegex activate \
        "WSL: cmd.exe available in activation environment"
    '';
  };
}
