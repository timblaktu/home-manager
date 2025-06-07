{
  home.file."test.txt" = {
    text = "test content";
    supportReadingFromWindows = true;
  };

  test.stubs.targets = { };

  test.asserts.assertions.expected = [
    ''
      Files configured with supportReadingFromWindows require WSL targets module.
      
      Please add to your configuration:
      
          targets.wsl = {
            enable = true;
            windowsTools.enablePowerShell = true;
          }
      
      This enables PowerShell access during activation for Windows shortcut creation.''
  ];
}
