#!/usr/bin/env bash
# Script to create Windows-compatible symlinks for specified files
# Used by Home Manager activation when supportReadingFromWindows is enabled

set -euo pipefail

# Check if we're in WSL environment
if [[ ! -f /proc/version ]] || ! grep -qi "microsoft\|wsl" /proc/version; then
    # Not in WSL, skip Windows symlink creation
    exit 0
fi

# Check if we have the required tools
if ! command -v powershell.exe >/dev/null 2>&1; then
    echo "Warning: powershell.exe not found, cannot create Windows symlinks" >&2
    exit 0
fi

# Function to create Windows symlink
create_windows_symlink() {
    local target_path="$1"
    local link_path="$2"
    
    # Convert paths to Windows format
    local windows_target
    local windows_link
    
    # Use wslpath to convert if available, otherwise manual conversion
    if command -v wslpath >/dev/null 2>&1; then
        windows_target=$(wslpath -w "$target_path")
        windows_link=$(wslpath -w "$link_path")
    else
        # Manual conversion for basic cases (fallback)
        windows_target="\\\\wsl\$\\Ubuntu${target_path}"
        windows_link="\\\\wsl\$\\Ubuntu${link_path}"
    fi
    
    # Remove existing link if it exists (should be the WSL symlink)
    if [[ -L "$link_path" ]]; then
        rm "$link_path"
    elif [[ -e "$link_path" ]]; then
        echo "Warning: $link_path exists but is not a symlink, skipping Windows symlink creation" >&2
        return 1
    fi
    
    # Create Windows symlink using PowerShell
    # Use -ErrorAction SilentlyContinue to avoid verbose errors
    if powershell.exe -Command "try { New-Item -ItemType SymbolicLink -Path '$windows_link' -Target '$windows_target' -Force -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }" 2>/dev/null; then
        echo "Created Windows symlink: $link_path -> $target_path"
        return 0
    else
        echo "Warning: Failed to create Windows symlink for $link_path" >&2
        echo "  You may need to enable Developer Mode or run as Administrator" >&2
        
        # Fall back to regular symlink if Windows symlink creation failed
        ln -sf "$target_path" "$link_path"
        return 1
    fi
}

# Main function that processes a list of files
process_files() {
    local home_files_path="$1"
    shift
    
    local failed_count=0
    
    for file_spec in "$@"; do
        # Parse file specification: "target_path:source_path"
        IFS=':' read -r target_path source_path <<< "$file_spec"
        
        local full_link_path="$HOME/$target_path"
        local full_source_path="$home_files_path/$target_path"
        
        # Verify the source exists
        if [[ ! -e "$full_source_path" ]]; then
            echo "Warning: Source file $full_source_path does not exist, skipping" >&2
            ((failed_count++))
            continue
        fi
        
        # Get the actual target that the home-files symlink points to
        if [[ -L "$full_source_path" ]]; then
            actual_target=$(readlink "$full_source_path")
            # If relative, make it absolute
            if [[ "$actual_target" != /* ]]; then
                actual_target="$(dirname "$full_source_path")/$actual_target"
            fi
            actual_target=$(realpath "$actual_target")
        else
            actual_target="$full_source_path"
        fi
        
        echo "Processing Windows symlink for: $target_path"
        echo "  Link: $full_link_path"
        echo "  Target: $actual_target"
        
        if create_windows_symlink "$actual_target" "$full_link_path"; then
            echo "  ✓ Success"
        else
            echo "  ✗ Failed"
            ((failed_count++))
        fi
        echo
    done
    
    if [[ $failed_count -gt 0 ]]; then
        echo "Warning: $failed_count Windows symlink(s) failed to create" >&2
        echo "Consider enabling Developer Mode or running with Administrator privileges" >&2
    else
        echo "All Windows symlinks created successfully!"
    fi
}

# Script entry point
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <home-files-path> [file1:source1] [file2:source2] ..." >&2
    exit 1
fi

process_files "$@"
