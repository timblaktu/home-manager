# Test: WSL integration dependency checks
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

    targets.wsl = {
      enable = true;
      windowsTools.enablePowerShell = true;
      windowsTools.enableWslPath = true;
    };

    home.file."integration-test.md" = {
      text = "# Integration Test\nThis tests WSL + Windows symlinks";
      supportReadingFromWindows = true;
    };
  };

  test.stubs.targets = { };

  nmt.script = ''
    # Verify WSL tools check activation step
    assertFileContains home-files/activate "wslToolsCheck"
    
    # Check Windows shortcuts activation step exists
    assertFileContains home-files/activate "createWindowsShortcuts"
    
    # Verify conditional logic works correctly
    assertFileContains home-files/activate "WSL targets module PowerShell"
  '';
}