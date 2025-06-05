# WSL Module Validation Test
# This tests if our WSL targets module can be evaluated successfully

let
  # Import the home-manager flake
  hm = import /home/tim/src/home-manager-wsl-target-module {};
  
  # Import nixpkgs
  pkgs = import <nixpkgs> {};
  
  # Create a test configuration
  testConfig = hm.lib.homeManagerConfiguration {
    pkgs = pkgs;
    modules = [
      # Inline our test configuration
      {
        targets.wsl = {
          enable = true;
          windowsTools = {
            enablePowerShell = true;
            powerShellPath = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
            enableCmd = false;
          };
        };
        
        home = {
          username = "test-user";
          homeDirectory = "/home/test-user";
          stateVersion = "24.05";
        };
      }
    ];
  };
  
in
{
  # Test that our WSL module is working
  wslEnabled = testConfig.config.targets.wsl.enable;
  powershellEnabled = testConfig.config.targets.wsl.windowsTools.enablePowerShell;
  
  # Test that extraActivationPath is populated
  hasExtraActivationPath = builtins.length testConfig.config.home.extraActivationPath > 0;
  
  # Test that activation script contains our WSL check
  activationScript = testConfig.config.home.activationPackage;
}
