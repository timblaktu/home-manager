#!/usr/bin/env bash
for test in files-windows-symlinks-{basic,wsl-integration,disabled,recursive,assertions,integration}; do
  if nix build ".#checks.x86_64-linux.$test" --option warn-dirty false; then
    printf "PASS $test\n"
  else
    printf "FAIL $test\n"
  fi
done
