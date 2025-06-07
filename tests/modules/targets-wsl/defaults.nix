{ config, lib, pkgs, ... }:

{
  config = {
    targets.wsl.enable = true;

    nmt.script = ''
      # Check that no tools are enabled by default
      assertFileNotRegex activate \
        "wsl-powershell-wrapper"
      assertFileNotRegex activate \
        "wsl-cmd-wrapper"
      assertFileNotRegex activate \
        "wsl-wslpath-wrapper"
        
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
