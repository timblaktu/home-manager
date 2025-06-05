# Simple test configuration for WSL targets module
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Enable WSL targets with PowerShell support
  targets.wsl = {
    enable = true;  # Force enable for testing
    windowsTools = {
      enablePowerShell = true;
      powerShellPath = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
      enableCmd = false;  # Disable cmd for cleaner testing
    };
  };

  # Basic home-manager config for testing
  home = {
    username = "test-user";
    homeDirectory = "/home/test-user";
    stateVersion = "24.05";
  };

  # Let's also add a simple file to test the combination with potential windows symlinks
  home.file."test-wsl-integration.txt" = {
    text = "WSL integration test file";
  };
}
