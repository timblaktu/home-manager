{
  home.username = "hm-user";
  home.homeDirectory = "/home/hm-user";
  home.stateVersion = "23.11";
  
  targets.wsl = {
    enable = true;
    windowsTools.enablePowerShell = true;
  };

  home.file."test.txt" = {
    text = "test file content";
    supportReadingFromWindows = true;
  };

  test.stubs.targets = { };

  nmt.script = ''
    assertFileExists home-files/test.txt
    assertFileContent home-files/test.txt <(printf "test file content")
  '';
}
