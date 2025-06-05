{ config, ... }:

# Test configuration for Windows symlink support
# This demonstrates usage of the new supportReadingFromWindows option

{
  home.file."test-windows-symlink.md" = {
    text = ''
      # Test Windows Symlink Support
      
      This file is used to test the Windows symlink compatibility feature
      in Home Manager for WSL environments.
      
      If you can read this file from a Windows application (like Edge browser
      with markdown preview), then the feature is working correctly.
    '';
    supportReadingFromWindows = true;
  };

  # Example with source file
  home.file."test-source-symlink.txt" = {
    source = ./test-file.txt;
    supportReadingFromWindows = true;
  };
}
