{
  home.username = "hm-user";
  home.homeDirectory = "/home/hm-user";
  home.stateVersion = "23.11";

  targets.wsl = {
    enable = true;
    windowsTools.enablePowerShell = true;
  };

  home.file = {
    "docs/readme.txt" = {
      text = "documentation";
      supportReadingFromWindows = true;
    };
    "config/deep/nested.conf" = {
      text = "nested config";
      supportReadingFromWindows = true;
    };
  };

  test.stubs.targets = { };

  nmt.script = ''
    assertFileExists home-files/docs/readme.txt
    assertFileExists home-files/config/deep/nested.conf
    assertFileContent home-files/docs/readme.txt <(printf "documentation")
    assertFileContent home-files/config/deep/nested.conf <(printf "nested config")
  '';
}
