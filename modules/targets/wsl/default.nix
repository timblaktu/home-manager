{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.targets.wsl;

in

{
  meta.maintainers = with maintainers; [ ];

  options.targets.wsl = {
    enable = mkEnableOption "WSL (Windows Subsystem for Linux) compatibility tweaks";

    windowsTools = {
      enablePowerShell = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable PowerShell wrapper in the activation environment.
        '';
      };

      powerShellPath = mkOption {
        type = types.str;
        default = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
        description = ''
          Path to PowerShell executable on the Windows host.
        '';
      };

      enableCmd = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable cmd.exe wrapper in the activation environment.
        '';
      };

      cmdPath = mkOption {
        type = types.str;
        default = "/mnt/c/Windows/System32/cmd.exe";
        description = ''
          Path to cmd.exe executable on the Windows host.
        '';
      };

      enableWslPath = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable wslpath wrapper in the activation environment.
        '';
      };

      wslPathPath = mkOption {
        type = types.str;
        default = "/usr/bin/wslpath";
        description = ''
          Path to wslpath executable.
        '';
      };
    };

    windowsTerminal = {
      enable = mkEnableOption "Windows Terminal settings management";

      colorSchemes = mkOption {
        type = types.listOf types.attrs;
        default = [ ];
        description = ''
          Color schemes to merge into Windows Terminal settings.json.
          Each scheme is merged into the schemes array if not already present.
        '';
        example = literalExpression ''
          [{
            name = "Solarized Dark (Correct)";
            background = "#002b36";
            foreground = "#839496";
            black = "#073642";
            red = "#dc322f";
            green = "#859900";
            yellow = "#b58900";
            blue = "#268bd2";
            purple = "#d33682";
            cyan = "#2aa198";
            white = "#eee8d5";
            brightBlack = "#002b36";
            brightRed = "#cb4b16";
            brightGreen = "#586e75";
            brightYellow = "#657b83";
            brightBlue = "#839496";
            brightPurple = "#6c71c4";
            brightCyan = "#93a1a1";
            brightWhite = "#fdf6e3";
          }]
        '';
      };

      defaultColorScheme = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Default color scheme name to set in profiles.defaults.
          If null, profiles.defaults.colorScheme is not modified.
        '';
        example = "Solarized Dark (Correct)";
      };

      keybindings = mkOption {
        type = types.listOf types.attrs;
        default = [ ];
        description = ''
          Keybindings to add to Windows Terminal settings.json.
          Existing keybindings are preserved unless they conflict.
        '';
        example = literalExpression ''
          [
            { command = "nextTab"; keys = "ctrl+tab"; }
            { command = "prevTab"; keys = "ctrl+shift+tab"; }
          ]
        '';
      };

      font = mkOption {
        type = types.nullOr types.attrs;
        default = null;
        description = ''
          Font configuration to set in profiles.defaults.
          If null, font settings are not modified.
        '';
        example = literalExpression ''
          {
            face = "CaskaydiaMono Nerd Font Mono, Noto Color Emoji";
            size = 11;
          }
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # Ensure PowerShell is enabled if Windows Terminal management is enabled
    targets.wsl.windowsTools.enablePowerShell = mkIf cfg.windowsTerminal.enable (mkDefault true);

    home.extraActivationPath =
      let
        # Create wrapper with the natural tool name and optional extension-less alias
        # This provides both powershell.exe/powershell, cmd.exe/cmd for better UX
        wrapperFor = toolName: path: extensionlessAlias:
          let
            mainWrapper = pkgs.writeShellScriptBin toolName ''
              exec "${path}" "$@"
            '';
            aliasWrapper =
              if extensionlessAlias != null then
                pkgs.writeShellScriptBin extensionlessAlias ''
                  exec "${path}" "$@"
                ''
              else null;
          in
          [ mainWrapper ] ++ (if aliasWrapper != null then [ aliasWrapper ] else [ ]);

        toolWrappers = lib.flatten ([ ]
          ++ optional cfg.windowsTools.enablePowerShell (wrapperFor "powershell.exe" cfg.windowsTools.powerShellPath "powershell")
          ++ optional cfg.windowsTools.enableCmd (wrapperFor "cmd.exe" cfg.windowsTools.cmdPath "cmd")
          ++ optional cfg.windowsTools.enableWslPath (wrapperFor "wslpath" cfg.windowsTools.wslPathPath null));

      in
      toolWrappers;

    home.activation.wslToolsCheck = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # WSL tools availability checks
      ${optionalString cfg.windowsTools.enablePowerShell ''
        if [[ -x "${cfg.windowsTools.powerShellPath}" ]]; then
          verboseEcho "WSL: PowerShell available in activation environment"
        else
          echo "WSL: Warning - PowerShell not found at ${cfg.windowsTools.powerShellPath}"
        fi
      ''}

      ${optionalString cfg.windowsTools.enableCmd ''
        if [[ -x "${cfg.windowsTools.cmdPath}" ]]; then
          verboseEcho "WSL: cmd.exe available in activation environment"
        else
          echo "WSL: Warning - cmd.exe not found at ${cfg.windowsTools.cmdPath}"
        fi
      ''}

      ${optionalString cfg.windowsTools.enableWslPath ''
        if [[ -x "${cfg.windowsTools.wslPathPath}" ]]; then
          verboseEcho "WSL: wslpath available in activation environment"
        else
          echo "WSL: Warning - wslpath not found at ${cfg.windowsTools.wslPathPath}"
        fi
      ''}

      # End WSL tools check
    '';

    # Windows Terminal settings management
    home.activation.windowsTerminalConfig = mkIf cfg.windowsTerminal.enable (
      lib.hm.dag.entryAfter [ "writeBoundary" ] (
        let
          # Convert Nix attrs to JSON
          colorSchemesJson = builtins.toJSON cfg.windowsTerminal.colorSchemes;
          keybindingsJson = builtins.toJSON cfg.windowsTerminal.keybindings;
          fontJson = if cfg.windowsTerminal.font != null then builtins.toJSON cfg.windowsTerminal.font else "null";
          defaultColorScheme = if cfg.windowsTerminal.defaultColorScheme != null then cfg.windowsTerminal.defaultColorScheme else "";

          # PowerShell script to merge settings
          updateScript = pkgs.writeText "update-windows-terminal.ps1" ''
            # Windows Terminal Settings Merge Script
            # Generated by home-manager targets.wsl.windowsTerminal

            $ErrorActionPreference = "Stop"

            # Find Windows Terminal settings.json
            $settingsPaths = @(
                "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
                "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
            )

            $settingsPath = $settingsPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

            if (-not $settingsPath) {
                Write-Host "Windows Terminal settings.json not found - skipping Terminal configuration" -ForegroundColor Yellow
                exit 0
            }

            Write-Host "Updating Windows Terminal settings: $settingsPath" -ForegroundColor Cyan

            try {
                # Read current settings
                $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

                # Create backup
                $backupPath = "$settingsPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Copy-Item $settingsPath $backupPath -Force
                Write-Host "  Created backup: $backupPath" -ForegroundColor Gray

                # Merge color schemes
                $newSchemes = '${colorSchemesJson}' | ConvertFrom-Json
                if ($newSchemes.Count -gt 0) {
                    if (-not $settings.schemes) {
                        $settings | Add-Member -Name "schemes" -Value @() -MemberType NoteProperty -Force
                    }

                    foreach ($newScheme in $newSchemes) {
                        $existingScheme = $settings.schemes | Where-Object { $_.name -eq $newScheme.name }
                        if ($existingScheme) {
                            Write-Host "  Updating color scheme: $($newScheme.name)" -ForegroundColor Gray
                            # Update existing scheme
                            foreach ($prop in $newScheme.PSObject.Properties) {
                                $existingScheme | Add-Member -Name $prop.Name -Value $prop.Value -MemberType NoteProperty -Force
                            }
                        } else {
                            Write-Host "  Adding color scheme: $($newScheme.name)" -ForegroundColor Gray
                            $settings.schemes += $newScheme
                        }
                    }
                }

                # Set default color scheme in profiles.defaults
                $defaultScheme = "${defaultColorScheme}"
                if ($defaultScheme -ne "") {
                    if (-not $settings.profiles.defaults) {
                        $settings.profiles | Add-Member -Name "defaults" -Value @{} -MemberType NoteProperty -Force
                    }
                    $settings.profiles.defaults | Add-Member -Name "colorScheme" -Value $defaultScheme -MemberType NoteProperty -Force
                    Write-Host "  Set default color scheme: $defaultScheme" -ForegroundColor Gray
                }

                # Set font in profiles.defaults
                $fontConfig = ${fontJson}
                if ($fontConfig -ne $null) {
                    if (-not $settings.profiles.defaults) {
                        $settings.profiles | Add-Member -Name "defaults" -Value @{} -MemberType NoteProperty -Force
                    }
                    if (-not $settings.profiles.defaults.font) {
                        $settings.profiles.defaults | Add-Member -Name "font" -Value @{} -MemberType NoteProperty -Force
                    }
                    foreach ($prop in $fontConfig.PSObject.Properties) {
                        $settings.profiles.defaults.font | Add-Member -Name $prop.Name -Value $prop.Value -MemberType NoteProperty -Force
                    }
                    Write-Host "  Updated font configuration" -ForegroundColor Gray
                }

                # Merge keybindings (future: deduplicate)
                $newKeybindings = '${keybindingsJson}' | ConvertFrom-Json
                if ($newKeybindings.Count -gt 0) {
                    if (-not $settings.actions) {
                        $settings | Add-Member -Name "actions" -Value @() -MemberType NoteProperty -Force
                    }
                    foreach ($binding in $newKeybindings) {
                        $settings.actions += $binding
                    }
                    Write-Host "  Added $($newKeybindings.Count) keybindings" -ForegroundColor Gray
                }

                # Write updated settings
                $settings | ConvertTo-Json -Depth 100 | Set-Content $settingsPath -Force

                Write-Host "Windows Terminal settings updated successfully" -ForegroundColor Green

            } catch {
                Write-Error "Failed to update Windows Terminal settings: $_"
                if (Test-Path $backupPath) {
                    Write-Host "Restoring from backup..." -ForegroundColor Yellow
                    Copy-Item $backupPath $settingsPath -Force
                }
                exit 1
            }
          '';
        in
        ''
          # Windows Terminal configuration management
          verboseEcho "Updating Windows Terminal settings..."

          if command -v powershell.exe >/dev/null 2>&1; then
            # Run PowerShell script to merge settings
            powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "${updateScript}")" 2>&1 | sed 's/\r$//'

            if [ $? -eq 0 ]; then
              verboseEcho "Windows Terminal settings updated"
            else
              echo "Warning: Failed to update Windows Terminal settings" >&2
            fi
          else
            echo "Warning: PowerShell not available, skipping Windows Terminal configuration" >&2
          fi
        ''
      )
    );
  };
}
