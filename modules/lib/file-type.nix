{ homeDirectory
, lib
, pkgs
,
}:

let
  inherit (lib)
    hasPrefix
    hm
    literalExpression
    mkDefault
    mkIf
    mkOption
    removePrefix
    types
    ;

  # Helper function to load sidecar .nix file if it exists
  loadSidecarConfig = source:
    let
      sidecarPath = "${toString source}.nix";
    in
    if builtins.pathExists sidecarPath then
      import sidecarPath { inherit lib pkgs; }
    else
      { };

  # Helper function to apply autoWriter when autoValidate is enabled
  applyAutoWriter = config:
    let
      sidecarConfig = loadSidecarConfig config.source;
      # Merge sidecar config with explicit config, explicit config takes precedence
      mergedDeps = (sidecarConfig.deps or [ ]) ++ (config.deps or [ ]);
      mergedOptions = (sidecarConfig.options or { }) // (config.options or { });

      sourceContent = builtins.readFile config.source;
      sourcePath = toString config.source;
    in
    if config.autoValidate then
      pkgs.writers.autoWriter
        {
          path = sourcePath;
          content = sourceContent;
          deps = mergedDeps;
          options = mergedOptions;
        }
    else
      config.source;
in
{
  # Constructs a type suitable for a `home.file` like option. The
  # target path may be either absolute or relative, in which case it
  # is relative the `basePath` argument (which itself must be an
  # absolute path).
  #
  # Arguments:
  #   - opt            the name of the option, for self-references
  #   - basePathDesc   docbook compatible description of the base path
  #   - basePath       the file base path
  fileType =
    opt: basePathDesc: basePath:
    types.attrsOf (
      types.submodule (
        { name, config, ... }:
        {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Whether this file should be generated. This option allows specific
                files to be disabled.
              '';
            };
            target = mkOption {
              type = types.str;
              apply =
                p:
                let
                  absPath = if hasPrefix "/" p then p else "${basePath}/${p}";
                in
                removePrefix (homeDirectory + "/") absPath;
              defaultText = literalExpression "name";
              description = ''
                Path to target file relative to ${basePathDesc}.
              '';
            };

            text = mkOption {
              default = null;
              type = types.nullOr types.lines;
              description = ''
                Text of the file. If this option is null then
                [](#opt-${opt}._name_.source)
                must be set.
              '';
            };

            source = mkOption {
              type = types.path;
              description = ''
                Path of the source file or directory. If
                [](#opt-${opt}._name_.text)
                is non-null then this option will automatically point to a file
                containing that text.
              '';
            };

            autoValidate = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Whether to automatically apply validation and build-time checking 
                based on file type detection. When enabled, the appropriate nixpkgs 
                writer (writeBash, writePython3, etc.) will be automatically selected 
                based on file extension and shebang detection.
                
                This provides automatic:
                - Syntax validation (shellcheck, flake8, etc.)
                - Build-time error detection
                - Dependency management
                - Language-specific optimizations
                
                Dependencies can be specified via the {option}`deps` option or 
                through a sidecar .nix file (e.g., script.py.nix).
              '';
            };

            deps = mkOption {
              type = types.listOf types.package;
              default = [ ];
              description = ''
                List of dependencies to include when {option}`autoValidate` is enabled.
                These dependencies will be passed to the appropriate writer function.
                
                For Python scripts, use packages from python3Packages.
                For Haskell programs, use packages from haskellPackages.
                For other languages, use the appropriate package set.
                
                Dependencies can also be specified in a sidecar .nix file.
              '';
              example = literalExpression ''
                [ 
                  python3Packages.requests 
                  python3Packages.click 
                ]
              '';
            };

            options = mkOption {
              type = types.attrs;
              default = { };
              description = ''
                Additional options to pass to the writer function when 
                {option}`autoValidate` is enabled. Different writers accept 
                different options:
                
                - Python: { doCheck = false; flakeIgnore = ["E501"]; }
                - Rust: { rustcArgs = ["-O"]; strip = true; }
                - Bash: { makeWrapperArgs = ["--set" "VAR" "value"]; }
                
                Options can also be specified in a sidecar .nix file.
              '';
              example = literalExpression ''
                { 
                  doCheck = false; 
                  flakeIgnore = ["E501" "W503"];
                }
              '';
            };

            executable = mkOption {
              type = types.nullOr types.bool;
              default = null;
              description = ''
                Set the execute bit. If `null`, defaults to the mode
                of the {var}`source` file or to `false`
                for files created through the {var}`text` option.
              '';
            };

            recursive = mkOption {
              type = types.bool;
              default = false;
              description = ''
                If the file source is a directory, then this option
                determines whether the directory should be recursively
                linked to the target location. This option has no effect
                if the source is a file.

                If `false` (the default) then the target
                will be a symbolic link to the source directory. If
                `true` then the target will be a
                directory structure matching the source's but whose leafs
                are symbolic links to the files of the source directory.
              '';
            };

            ignorelinks = mkOption {
              type = types.bool;
              default = false;
              description = ''
                When `recursive` is enabled, adds `-ignorelinks` flag to lndir

                It causes lndir to not treat symbolic links in the source directory specially.
                The link created in the target directory will point back to the corresponding
                (symbolic link) file in the source directory. If the link is to a directory
              '';
            };

            onChange = mkOption {
              type = types.lines;
              default = "";
              description = ''
                Shell commands to run when file has changed between
                generations. The script will be run
                *after* the new files have been linked
                into place.

                Note, this code is always run when `recursive` is
                enabled.
              '';
            };

            force = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Whether the target path should be unconditionally replaced
                by the managed file source. Warning, this will silently
                delete the target regardless of whether it is a file or
                link.
              '';
            };
          };

          config = {
            target = mkDefault name;

            # Enhanced source handling with autoValidate support
            source = mkIf (config.text != null) (
              mkDefault (
                pkgs.writeTextFile {
                  inherit (config) text;
                  executable = config.executable == true; # can be null
                  name = hm.strings.storeFileName name;
                }
              )
            );

            # Apply autoWriter transformation when autoValidate is enabled
            # This replaces the source with the writer output
            source = mkIf (config.autoValidate && config.text == null) (
              mkDefault (applyAutoWriter config)
            );
          };
        }
      )
    );
}
