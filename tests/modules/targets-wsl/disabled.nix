{ config, lib, pkgs, ... }:

{
  config = {
    targets.wsl.enable = false;

    nmt.script = ''
      # Check that no WSL tool wrappers are added when disabled
      assertFileNotRegex activate \
        "wsl-powershell-wrapper"
      assertFileNotRegex activate \
        "wsl-cmd-wrapper"  
      assertFileNotRegex activate \
        "wsl-wslpath-wrapper"
        
      # Check that no WSL tool availability checks are present
      assertFileNotRegex activate \
        "WSL: PowerShell available in activation environment"
      assertFileNotRegex activate \
        "WSL: Windows Command Prompt available in activation environment"
      assertFileNotRegex activate \
        "WSL: wslpath available in activation environment"
        
      # Verify no WSL-related activation entries
      assertFileNotRegex activate \
        "wslToolsCheck"
    '';
  };
}
