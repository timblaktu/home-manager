{ lib, ... }:

{
  meta.maintainers = with lib.maintainers; [ ]; # TODO: Add maintainer

  imports = [
    ./windows-tools.nix
  ];
}
