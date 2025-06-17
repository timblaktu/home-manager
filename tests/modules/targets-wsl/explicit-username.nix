{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    targets.wsl = {
      enable = true;
      windowsUsername = "explicit-user";
      windowsTools.enablePowerShell = true;
    };

    test.stubs.wsl = { };

    nmt.script = ''
      assertFileRegex home-files/test-explicit-config.txt "windowsUsernameFinal: explicit-user"
      assertFileRegex home-files/test-explicit-config.txt "windowsHomeDir: /mnt/c/Users/explicit-user"
    '';

    home.file."test-explicit-config.txt".text = ''
      windowsUsernameFinal: ${config.targets.wsl.windowsUsernameFinal}
      windowsHomeDir: ${config.targets.wsl.windowsHomeDir}
    '';
  };
}
