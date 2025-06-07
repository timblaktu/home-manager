# Test: Windows symlinks disabled when WSL module not configured  
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

    # WSL targets module disabled - should trigger assertion
    targets.wsl.enable = false;

    home.file."disabled-test.txt" = {
      text = "This should trigger assertion";
      supportReadingFromWindows = true;
    };
  };

  test.stubs.targets = { };

  # This test expects assertion failure
  test.asserts.assertions.expected = [
    "Files configured with supportReadingFromWindows require WSL targets module."
  ];
}