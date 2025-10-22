{
  home.file."bin/test-python" = {
    source = ./auto-validate-python.py;
    autoValidate = true;
  };

  home.file."bin/test-bash" = {
    source = ./auto-validate-bash.sh;
    autoValidate = true;
  };

  nmt.script = ''
    # Check that the files exist in the home-files output
    assertFileExists home-files/bin/test-python
    assertFileExists home-files/bin/test-bash
    
    # Check that they are executable (should be detected automatically)
    assertFileIsExecutable home-files/bin/test-python
    assertFileIsExecutable home-files/bin/test-bash
    
    # Check that the files are actually Nix store paths (meaning they went through writers)
    # The autoWriter should create store paths, not direct symlinks
    python_target=$(readlink home-files/bin/test-python)
    bash_target=$(readlink home-files/bin/test-bash)
    
    if [[ ! "$python_target" =~ ^/nix/store/ ]]; then
      echo "Expected Python script to be a Nix store path, got: $python_target" >&2
      exit 1
    fi
    
    if [[ ! "$bash_target" =~ ^/nix/store/ ]]; then
      echo "Expected Bash script to be a Nix store path, got: $bash_target" >&2
      exit 1
    fi
    
    echo "✅ autoValidate basic test passed"
  '';
}
