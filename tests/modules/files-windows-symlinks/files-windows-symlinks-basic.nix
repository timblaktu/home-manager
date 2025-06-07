# Test: Basic Windows symlinks functionality with WSL integration
{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = {
    home.username = "hm-user";
    home.homeDirectory = "/home/hm-user";
    home.stateVersion = "23.11";

    # Enable WSL targets module for PowerShell access
    targets.wsl = {
      enable = true;
      windowsTools.enablePowerShell = true;
    };

    # Configure files with Windows symlinks support
    home.file = {
      "simple-file.txt" = {
        text = "Hello World from Home Manager";
        supportReadingFromWindows = true;
      };
      
      "config/app.conf" = {
        text = ''
          [settings]
          enabled = true
        '';
        supportReadingFromWindows = true;
      };
    };
  };

  test.stubs.targets = { };

  nmt.script = ''
    # Check that activation script contains Windows symlinks logic
    assertFileContains home-files/activate "createWindowsShortcuts"
    
    # Verify WSL integration checks
    assertFileContains home-files/activate "targets.wsl.windowsTools.enablePowerShell"
    
    # Check for PowerShell verification logic
    assertFileContains home-files/activate "command -v powershell.exe"
  '';
}