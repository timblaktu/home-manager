#!/usr/bin/env bash
# Script to create Windows shortcuts (.lnk files) for specified files
# Used by Home Manager activation when supportReadingFromWindows is enabled
# Optimized for GUI applications like Microsoft Edge, VS Code, etc.

set -euo pipefail

# Debug: Log script invocation
echo "DEBUG: Script started with $# arguments: $*" >&2
echo "DEBUG: Working directory: $PWD" >&2

# Check if we're in WSL environment
if [[ ! -f /proc/version ]] || ! grep -qi "microsoft\|wsl" /proc/version; then
    echo "DEBUG: Not in WSL environment, exiting" >&2
    exit 0
fi
echo "DEBUG: WSL environment confirmed" >&2

# Function to verify PowerShell availability from activation environment
# PowerShell should be provided by WSL targets module in activation PATH
verify_powershell() {
    if command -v powershell.exe >/dev/null 2>&1; then
        echo "DEBUG: PowerShell available from activation environment (WSL targets module)" >&2
        echo "powershell.exe"
        return 0
    else
        echo "ERROR: PowerShell not available in activation environment" >&2
        echo "ERROR: This should be provided by targets.wsl.windowsTools.enablePowerShell" >&2
        return 1
    fi
}

# Function to create Windows shortcut (.lnk file)
create_windows_shortcut() {
    local actual_target="$1"  # This is the resolved Nix store path
    local link_path="$2"     # This is the Linux symlink path (for reference)
    local powershell_cmd="$3"
    
    echo "DEBUG: Creating Windows shortcut that bypasses Linux symlink" >&2
    echo "DEBUG: Resolved target (Nix store): $actual_target" >&2
    echo "DEBUG: Linux symlink (reference): $link_path" >&2
    
    # Create Windows shortcut with .lnk suffix to coexist with Linux symlink
    local windows_shortcut_path="${link_path}.lnk"
    echo "DEBUG: Windows shortcut will be: $windows_shortcut_path" >&2
    
    # Remove any existing Windows shortcut (but leave Linux symlink alone!)
    if [[ -e "$windows_shortcut_path" ]]; then
        echo "DEBUG: Removing existing Windows shortcut: $windows_shortcut_path" >&2
        rm "$windows_shortcut_path"
    fi
    
    # Create the parent directory if it doesn't exist
    local parent_dir
    parent_dir="$(dirname "$windows_shortcut_path")"
    if [[ ! -d "$parent_dir" ]]; then
        echo "DEBUG: Creating parent directory: $parent_dir" >&2
        mkdir -p "$parent_dir"
    fi
    
    # Convert resolved target path (Nix store) to Windows UNC path
    # This bypasses the Linux symlink and points directly to the file
    local windows_target_path
    if command -v wslpath >/dev/null 2>&1; then
        windows_target_path=$(wslpath -w "$actual_target" 2>/dev/null)
        if [[ -z "$windows_target_path" ]]; then
            # Fallback: manually construct UNC path with proper formatting
            local clean_path="${actual_target#/}"  # Remove leading /
            clean_path="${clean_path//\/\\\\}"  # Convert / to \\
            windows_target_path="\\\\wsl.localhost\\NixOS\\$clean_path"
        fi
    else
        # Fallback: manually construct UNC path with proper formatting
        local clean_path="${actual_target#/}"  # Remove leading /
        clean_path="${clean_path//\/\\\\}"  # Convert / to \\
        windows_target_path="\\\\wsl.localhost\\NixOS\\$clean_path"
    fi
    
    # Convert WSL path to Windows path for the shortcut location
    local windows_shortcut_location
    if command -v wslpath >/dev/null 2>&1; then
        windows_shortcut_location=$(wslpath -w "$windows_shortcut_path" 2>/dev/null)
        if [[ -z "$windows_shortcut_location" ]]; then
            # Fallback: manually construct UNC path with proper formatting
            local clean_shortcut_path="${windows_shortcut_path#/}"  # Remove leading /
            clean_shortcut_path="${clean_shortcut_path//\/\\\\}"  # Convert / to \\
            windows_shortcut_location="\\\\wsl.localhost\\NixOS\\$clean_shortcut_path"
        fi
    else
        # Fallback: manually construct UNC path with proper formatting
        local clean_shortcut_path="${windows_shortcut_path#/}"  # Remove leading /
        clean_shortcut_path="${clean_shortcut_path//\/\\\\}"  # Convert / to \\
        windows_shortcut_location="\\\\wsl.localhost\\NixOS\\$clean_shortcut_path"
    fi
    
    echo "DEBUG: Creating Windows shortcut via PowerShell" >&2
    echo "DEBUG: Shortcut location: $windows_shortcut_location" >&2
    echo "DEBUG: Target path (direct to Nix store): $windows_target_path" >&2
    echo "DEBUG: Note: Bypassing Linux symlink, pointing directly to Nix store file" >&2
    
    # Test if the target is accessible through WSL bridge before creating shortcut
    echo "DEBUG: Testing WSL bridge access to Nix store target..." >&2
    if powershell.exe -Command "Test-Path '$windows_target_path'" 2>/dev/null | grep -q "True"; then
        echo "DEBUG: WSL bridge can access Nix store target file" >&2
    else
        echo "DEBUG: WARNING - WSL bridge cannot access Nix store target, shortcut may not work" >&2
    fi
    
    # Additional Edge-specific debugging
    echo "DEBUG: Testing file type detection..." >&2
    local file_extension="${windows_target_path##*.}"
    echo "DEBUG: File extension: $file_extension" >&2
    
    # Test if PowerShell can read the file content (Edge compatibility check)
    echo "DEBUG: Testing PowerShell file content access..." >&2
    if powershell.exe -Command "Get-Content '$windows_target_path' -TotalCount 1" 2>/dev/null | head -1; then
        echo "DEBUG: PowerShell can read file content - should work with Edge" >&2
    else
        echo "DEBUG: WARNING - PowerShell cannot read file content, Edge may fail" >&2
    fi
    
    # Create PowerShell script to create the shortcut
    local powershell_script="
        \$WshShell = New-Object -comObject WScript.Shell;
        \$Shortcut = \$WshShell.CreateShortcut('$windows_shortcut_location');
        \$Shortcut.TargetPath = '$windows_target_path';
        \$Shortcut.Save();
        Write-Host 'Windows shortcut created successfully';
    "
    
    # Execute PowerShell command to create shortcut (with full error reporting)
    echo "DEBUG: Executing PowerShell command..." >&2
    if "$powershell_cmd" -Command "$powershell_script"; then
        echo "DEBUG: PowerShell command succeeded" >&2
        
        # Verify the shortcut was actually created and is valid
        if [[ -f "$windows_shortcut_path" ]]; then
            local file_size
            file_size=$(stat -c%s "$windows_shortcut_path" 2>/dev/null || echo "0")
            if [[ "$file_size" -gt 100 ]]; then
                echo "✓ Created Windows shortcut: $windows_shortcut_path -> (direct to Nix store)" 
                echo "  Linux symlink: $link_path -> $actual_target"
                echo "  Windows shortcut: $windows_shortcut_location -> $windows_target_path"
                echo "  (Double-click from Windows Explorer: $windows_shortcut_location)"
                echo "  (Or use in Windows file dialogs for GUI applications)"
                echo "  (File size: ${file_size} bytes - indicates valid shortcut)"
                echo "  (If Edge fails to open: try right-click -> Open with -> Choose another app)"
                return 0
            else
                echo "✗ Windows shortcut file too small (${file_size} bytes) - likely creation failed" >&2
                return 1
            fi
        else
            echo "✗ Windows shortcut file not found after PowerShell execution" >&2
            return 1
        fi
    else
        local ps_exit_code=$?
        echo "✗ Failed to create Windows shortcut: $windows_shortcut_path" >&2
        echo "  PowerShell command failed with exit code: $ps_exit_code" >&2
        return 1
    fi
}

# Main processing function
process_files() {
    local home_files_path="$1"
    shift
    
    # Verify PowerShell availability from WSL targets module
    local powershell_cmd
    if ! powershell_cmd=$(verify_powershell); then
        echo "Error: PowerShell not accessible during activation" >&2
        echo "Windows shortcuts cannot be created without PowerShell access" >&2
        echo "Ensure targets.wsl.windowsTools.enablePowerShell is enabled" >&2
        echo "This is non-fatal for home-manager activation - continuing..." >&2
        return 0  # Return success despite the error - don't fail activation
    fi
    
    local success_count=0
    local failed_count=0
    
    echo "Creating Windows shortcuts (GUI application optimized)..." >&2
    echo "DEBUG: Processing ${#@} file specifications" >&2
    echo "DEBUG: Using PowerShell: $powershell_cmd" >&2
    
    for file_spec in "$@"; do
        # Parse file specification: "target_path:source_path"
        IFS=':' read -r target_path source_path <<< "$file_spec"
        
        local full_link_path="$HOME/$target_path"
        local full_source_path="$home_files_path/$target_path"
        
        echo "DEBUG: Processing file spec: $file_spec" >&2
        echo "DEBUG:   target_path: $target_path" >&2
        echo "DEBUG:   source_path: $source_path" >&2
        echo "DEBUG:   full_link_path: $full_link_path" >&2
        echo "DEBUG:   full_source_path: $full_source_path" >&2
        
        # Verify the source exists in home-files
        if [[ ! -e "$full_source_path" ]]; then
            echo "Warning: Source file $full_source_path does not exist, skipping" >&2
            ((failed_count++))
            continue
        fi
        
        # Resolve the actual target that the home-files symlink points to
        local actual_target
        if [[ -L "$full_source_path" ]]; then
            actual_target=$(readlink "$full_source_path")
            # Convert relative paths to absolute
            if [[ "$actual_target" != /* ]]; then
                actual_target="$(dirname "$full_source_path")/$actual_target"
            fi
            # Canonicalize the path
            actual_target=$(realpath "$actual_target")
            echo "DEBUG: Resolved symlink target: $actual_target" >&2
        else
            actual_target="$full_source_path"
            echo "DEBUG: Using direct file path: $actual_target" >&2
        fi
        
        # Verify the final target exists and is accessible
        if [[ ! -e "$actual_target" ]]; then
            echo "Warning: Final target $actual_target does not exist, skipping" >&2
            ((failed_count++))
            continue
        fi
        
        echo "Processing Windows shortcut for: $target_path"
        echo "  Linux symlink (unchanged): $full_link_path -> $actual_target"  
        echo "  Windows shortcut (creating): ${full_link_path}.lnk -> (direct to Nix store)"
        echo "  Final target: $actual_target"
        
        if create_windows_shortcut "$actual_target" "$full_link_path" "$powershell_cmd"; then
            ((success_count++))
            echo success
        else
            ((failed_count++))
            echo fail
        fi
        printf "\nsuccess_count=$success_count failed_count=$failed_count\n\n"
    done
    
    echo "Windows shortcut creation summary:" >&2
    echo "  ✓ Successful: $success_count" >&2
    echo "  ✗ Failed: $failed_count" >&2
    
    if [[ $failed_count -gt 0 ]]; then
        echo "Note: Some Windows shortcuts could not be created - check PowerShell access" >&2
        echo "Linux symlinks remain unchanged and functional for WSL access" >&2
        echo "DEBUG: Continuing despite $failed_count failures - non-fatal for activation" >&2
        return 0  # Return success despite failures - don't fail home-manager activation
    else
        echo "All Windows shortcuts created successfully alongside existing Linux symlinks!" >&2
        echo "Double-click shortcuts from Windows Explorer or use in GUI file dialogs" >&2
        echo "DEBUG: Exiting with code 0 - all successful" >&2
        return 0
    fi
}

# Script entry point
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <home-files-path> [file1:source1] [file2:source2] ..." >&2
    echo >&2
    echo "This script creates Windows shortcuts (.lnk files) for Home Manager files" >&2
    echo "that have supportReadingFromWindows enabled." >&2
    echo "Shortcuts work optimally with GUI applications and file dialogs." >&2
    echo >&2
    echo "Arguments:" >&2
    echo "  home-files-path  Path to the home-manager-files store directory" >&2
    echo "  file*:source*    File specifications in format 'target:source'" >&2
    exit 0  # Exit successfully even when showing help - don't fail home-manager activation
fi

home_files_path="$1"
shift

# Validate home-files path
if [[ ! -d "$home_files_path" ]]; then
    echo "Error: Home files path does not exist: $home_files_path" >&2
    exit 0  # Exit successfully despite the error - don't fail home-manager activation
fi

echo "DEBUG: Home files path: $home_files_path" >&2
echo "DEBUG: Will process ${#@} file specifications" >&2

# Process files but don't propagate error code to home-manager
process_files "$home_files_path" "$@"
exit 0  # Always exit with success code for home-manager activation
