{ pkgs, ... }:

{
  home.file."bin/test-python-with-deps" = {
    source = ./auto-validate-python.py;
    autoValidate = true;
    deps = with pkgs.python3Packages; [
      requests
      click
    ];
    options = {
      doCheck = false;
      flakeIgnore = [ "E501" "W503" ];
    };
  };

  nmt.script = ''
    # Check that the file exists and is processed
    assertFileExists home-files/bin/test-python-with-deps
    assertFileIsExecutable home-files/bin/test-python-with-deps
    
    # Verify it's a store path (processed by autoWriter with deps)
    target=$(readlink home-files/bin/test-python-with-deps)
    if [[ ! "$target" =~ ^/nix/store/ ]]; then
      echo "Expected script to be processed by autoWriter with deps, got: $target" >&2
      exit 1
    fi
    
    echo "✅ autoValidate deps test passed"
  '';
}
