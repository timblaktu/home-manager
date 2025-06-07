# Test: Complete home-manager configuration with WSL Windows integration
{
  home.username = "hm-user";
  home.homeDirectory = "/home/hm-user";
  home.stateVersion = "23.11";

  targets.wsl = {
    enable = true;
    windowsTools.enablePowerShell = true;
  };

  home.file = {
    "document.pdf" = {
      text = "PDF content";
      supportReadingFromWindows = true;
    };
    "config/app.conf" = {
      text = "[settings]\nenabled = true";
      supportReadingFromWindows = true;
    };
    "scripts/build.sh" = {
      text = "#!/bin/bash\necho 'building'";
      executable = true;
      supportReadingFromWindows = true;
    };
  };

  test.stubs.targets = { };

  nmt.script = ''
    # Verify home-manager generation builds successfully
    assertFileExists home-files/document.pdf
    assertFileExists home-files/config/app.conf
    assertFileExists home-files/scripts/build.sh
    
    # Verify file contents
    assertFileContent home-files/document.pdf <(printf "PDF content")
    assertFileContent home-files/config/app.conf <(printf "[settings]\nenabled = true")
    assertFileContent home-files/scripts/build.sh <(printf "#!/bin/bash\necho 'building'")
    
    # Verify executable bit preserved
    assertFileIsExecutable home-files/scripts/build.sh
  '';
}
