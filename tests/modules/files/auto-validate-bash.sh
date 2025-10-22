#!/bin/bash
# Test Bash script for autoValidate functionality

set -euo pipefail

main() {
    echo "Hello from auto-validated Bash script!"
    echo "Current directory: $(pwd)"
    echo "User: ${USER:-unknown}"
}

main "$@"