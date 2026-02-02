#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$PROJECT_ROOT/lib/utils/logging.sh"

# Only run if interactive
if [[ -t 0 ]]; then
    echo ""
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "🦙 OLLAMA HARDWARE CONFIGURATION"
    log_info "═══════════════════════════════════════════════════════════════"
    echo ""

    ENV_FILE="$SCRIPT_DIR/.env"
    
    # Check if already configured
    if [ -f "$ENV_FILE" ] && grep -q "OLLAMA_HARDWARE_PROFILE" "$ENV_FILE"; then
        log_info "Ollama is already configured. Skipping hardware selection."
        exit 0
    fi

    echo "Select hardware acceleration for Ollama:"
    echo "1) CPU Only (Universal compatibility, slower)"
    echo "2) NVIDIA GPU (Requires NVIDIA Container Toolkit)"
    echo "3) AMD GPU (ROCm, requires supported AMD GPU)"
    
    read -p "Enter choice [1-3]: " CHOICE

    # Default to CPU
    OLLAMA_CPU_PROFILE="ollama-cpu-disabled"
    OLLAMA_GPU_PROFILE="ollama-gpu-disabled"
    OLLAMA_AMD_PROFILE="ollama-amd-disabled"
    HARDWARE_TYPE="cpu"

    case "$CHOICE" in
        2)
            OLLAMA_GPU_PROFILE="ollama"
            HARDWARE_TYPE="nvidia"
            log_info "Selected: NVIDIA GPU"
            ;;
        3)
            OLLAMA_AMD_PROFILE="ollama"
            HARDWARE_TYPE="amd"
            log_info "Selected: AMD GPU"
            ;;
        *)
            OLLAMA_CPU_PROFILE="ollama"
            HARDWARE_TYPE="cpu"
            log_info "Selected: CPU Only"
            ;;
    esac

    # Update .env using sed
    if [ -f "$ENV_FILE" ]; then
        # Update Hardware Profile
        if grep -q "OLLAMA_HARDWARE_PROFILE=" "$ENV_FILE"; then
            sed -i "s|^OLLAMA_HARDWARE_PROFILE=.*|OLLAMA_HARDWARE_PROFILE=$HARDWARE_TYPE|" "$ENV_FILE"
        else
            echo "OLLAMA_HARDWARE_PROFILE=$HARDWARE_TYPE" >> "$ENV_FILE"
        fi

        # Update CPU Profile
        if grep -q "OLLAMA_CPU_PROFILE=" "$ENV_FILE"; then
            sed -i "s|^OLLAMA_CPU_PROFILE=.*|OLLAMA_CPU_PROFILE=$OLLAMA_CPU_PROFILE|" "$ENV_FILE"
        else
            echo "OLLAMA_CPU_PROFILE=$OLLAMA_CPU_PROFILE" >> "$ENV_FILE"
        fi

        # Update GPU Profile
        if grep -q "OLLAMA_GPU_PROFILE=" "$ENV_FILE"; then
            sed -i "s|^OLLAMA_GPU_PROFILE=.*|OLLAMA_GPU_PROFILE=$OLLAMA_GPU_PROFILE|" "$ENV_FILE"
        else
            echo "OLLAMA_GPU_PROFILE=$OLLAMA_GPU_PROFILE" >> "$ENV_FILE"
        fi

        # Update AMD Profile
        if grep -q "OLLAMA_AMD_PROFILE=" "$ENV_FILE"; then
            sed -i "s|^OLLAMA_AMD_PROFILE=.*|OLLAMA_AMD_PROFILE=$OLLAMA_AMD_PROFILE|" "$ENV_FILE"
        else
            echo "OLLAMA_AMD_PROFILE=$OLLAMA_AMD_PROFILE" >> "$ENV_FILE"
        fi
    else
        log_error ".env file not found. Please run secrets generation first."
        exit 1
    fi

    log_success "✅ Ollama configuration updated."
else
    # Non-interactive mode: Ensure defaults are set if not present
    ENV_FILE="$SCRIPT_DIR/.env"
    if [ -f "$ENV_FILE" ]; then
        # Ensure variables exist, default to CPU if missing
        if ! grep -q "OLLAMA_HARDWARE_PROFILE=" "$ENV_FILE"; then
             echo "OLLAMA_HARDWARE_PROFILE=cpu" >> "$ENV_FILE"
        fi
        if ! grep -q "OLLAMA_CPU_PROFILE=" "$ENV_FILE"; then
             echo "OLLAMA_CPU_PROFILE=ollama" >> "$ENV_FILE"
        fi
        if ! grep -q "OLLAMA_GPU_PROFILE=" "$ENV_FILE"; then
             echo "OLLAMA_GPU_PROFILE=ollama-gpu-disabled" >> "$ENV_FILE"
        fi
        if ! grep -q "OLLAMA_AMD_PROFILE=" "$ENV_FILE"; then
             echo "OLLAMA_AMD_PROFILE=ollama-amd-disabled" >> "$ENV_FILE"
        fi
    fi
fi
