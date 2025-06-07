{
  home.username = "hm-user";
  home.homeDirectory = "/home/hm-user";
  home.stateVersion = "23.11";

  targets.wsl = {
    enable = true;
    windowsTools.enablePowerShell = true;
  };

  home.file."simple-file.txt" = {
    text = "Hello World";
    supportReadingFromWindows = true;
  };

  test.stubs.targets = { };

  nmt.script = ''
    assertFileExists home-files/simple-file.txt
    assertFileContent home-files/simple-file.txt <(printf "Hello World")
  '';
}
