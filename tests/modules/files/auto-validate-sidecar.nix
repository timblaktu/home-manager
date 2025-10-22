{
  home.file."bin/test-python-with-sidecar" = {
    source = ./auto-validate-python.py;
    autoValidate = true;
    # Sidecar file auto-validate-python.py.nix should be loaded automatically
  };

  nmt.script = ''
    # Check that the file exists
    assertFileExists home-files/bin/test-python-with-sidecar
    assertFileIsExecutable home-files/bin/test-python-with-sidecar
    
    # Verify it's a store path (processed by autoWriter)
    target=$(readlink home-files/bin/test-python-with-sidecar)
    if [[ ! "$target" =~ ^/nix/store/ ]]; then
      echo "Expected script to be processed by autoWriter (store path), got: $target" >&2
      exit 1
    fi
    
    echo "✅ autoValidate sidecar test passed"
  '';
}
