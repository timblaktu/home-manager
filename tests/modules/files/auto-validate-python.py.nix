# Sidecar configuration for auto-validate-python.py
{ lib, pkgs }:

{
  deps = with pkgs.python3Packages; [
    # Example dependencies for the Python script
    requests
    click
  ];

  options = {
    # Disable syntax checking for test purposes
    doCheck = false;
    # Example flake8 ignore patterns
    flakeIgnore = [ "E501" ];
  };
}
