{
  files-disabled = ./disabled.nix;
  files-executable = ./executable.nix;
  files-hidden-source = ./hidden-source.nix;
  files-out-of-store-symlink = ./out-of-store-symlink.nix;
  files-source-with-spaces = ./source-with-spaces.nix;
  files-target-conflict = ./target-conflict.nix;
  files-target-with-shellvar = ./target-with-shellvar.nix;
  files-text = ./text.nix;

  # autoValidate feature tests
  files-auto-validate-basic = ./auto-validate-basic.nix;
  files-auto-validate-sidecar = ./auto-validate-sidecar.nix;
  files-auto-validate-deps = ./auto-validate-deps.nix;
  files-auto-validate-disabled = ./auto-validate-disabled.nix;
}
