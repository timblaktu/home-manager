{ config, lib, pkgs, ... }:

{
  config = {
    targets.wsl.enable = false;

    nmt.script = ''
      # Check that no WSL tools (including extension-less aliases) are added when disabled
      assertFileNotRegex activate \
        "powershell.exe"
      assertFileNotRegex activate \
        "[^.]powershell[^.]"
      assertFileNotRegex activate \
        "cmd.exe"  
      assertFileNotRegex activate \
        "[^.]cmd[^.]"
      assertFileNotRegex activate \
        "wslpath"
        
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
