# Test: Recursive directory Windows symlinks
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
    };

    home.file."project" = {
      source = pkgs.writeTextDir "docs/README.md" "# Project Documentation";
      recursive = true;
      supportReadingFromWindows = true;
    };
  };

  test.stubs.targets = { };

  nmt.script = ''
    assertFileContains home-files/activate "Processing recursive directory"
  '';
}