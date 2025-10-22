{
  home.file."bin/test-no-validation" = {
    source = ./auto-validate-python.py;
    autoValidate = false; # Explicitly disabled (default)
  };

  nmt.script = ''
    # Check that the file exists
    assertFileExists home-files/bin/test-no-validation
    
    # When autoValidate is false, should be a direct symlink to the source file
    # Not processed through writers, so should not be a store path from autoWriter
    target=$(readlink home-files/bin/test-no-validation)
    
    # The target should point to the original file path (via Nix store path)
    # but not be an autoWriter-generated script
    if [[ "$target" =~ auto-validate-python.py ]]; then
      echo "✅ autoValidate disabled - direct link to source file"
    else
      echo "Expected direct link to source file, got: $target" >&2
      exit 1
    fi
    
    echo "✅ autoValidate disabled test passed"
  '';
}
