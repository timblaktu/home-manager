{
  home.username = "hm-user";
  home.homeDirectory = "/home/hm-user";
  home.stateVersion = "23.11";

  targets.wsl = {
    enable = true;
    windowsTools.enablePowerShell = true;
  };

  home.file."test-file.txt" = {
    text = "content";
    supportReadingFromWindows = true;
  };

  test.stubs.targets = { };

  nmt.script = ''
    assertFileExists home-files/test-file.txt
    assertFileContent home-files/test-file.txt <(printf "content")
  '';
}
