# Test: Assertion checks for Windows symlinks configuration
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
    
    # Test with proper WSL configuration - should pass
    targets.wsl = {
      enable = true;
      windowsTools.enablePowerShell = true;
    };

    home.file."test.txt" = {
      text = "test file content";
      supportReadingFromWindows = true;
    };
  };

  test.stubs.targets = { };

  nmt.script = ''
    # Should build successfully with proper WSL config
    assertFileExists home-files/activate
    assertFileContains home-files/activate "createWindowsShortcuts"
  '';
}