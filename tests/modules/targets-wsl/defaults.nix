{ config, lib, pkgs, ... }:

{
  config = {
    targets.wsl.enable = true;

    nmt.script = ''
      # Check that no tools (including extension-less aliases) are enabled by default
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
        
      # Check that no tool availability checks are present when disabled
      assertFileNotRegex activate \
        "WSL: PowerShell available in activation environment"
      assertFileNotRegex activate \
        "WSL: wslpath available in activation environment"
      assertFileNotRegex activate \
        "WSL: cmd.exe available in activation environment"
        
      # Check that wslToolsCheck activation script is still present but mostly empty
      assertFileRegex activate \
        "wslToolsCheck"
    '';
  };
}
