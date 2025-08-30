#!/bin/bash

set -e

# Source utilities
source "$(dirname "$0")/utils.sh"

# Get project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
ENV_FILE="$PROJECT_ROOT/.env"

# Check if perplexica is in COMPOSE_PROFILES
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

if [[ "$COMPOSE_PROFILES" == *"perplexica"* ]]; then
    log_info "Perplexica selected - Setting up Perplexica repository..."
    
    cd "$PROJECT_ROOT"
    
    # Clone Perplexica if not exists
    if [ ! -d "perplexica" ]; then
        log_info "Cloning Perplexica repository..."
        git clone https://github.com/ItzCrazyKns/Perplexica.git perplexica || {
            log_error "Failed to clone Perplexica repository"
            exit 1
        }
    else
        log_info "Perplexica repository already exists"
    fi
    
    # Configure Perplexica
    cd perplexica
    
    if [ ! -f "config.toml" ]; then
        if [ ! -f "sample.config.toml" ]; then
            log_error "sample.config.toml not found in Perplexica repository"
            exit 1
        fi
        
        log_info "Configuring Perplexica..."
        cp sample.config.toml config.toml
        
        # Update Ollama API URL
        sed -i 's|API_URL = ""|API_URL = "http://ollama:11434"|' config.toml
        
        # Update SearXNG URL
        sed -i 's|SEARXNG = ""|SEARXNG = "http://searxng:8080"|' config.toml
        
        # If OpenAI API key exists in env, add it
        if [ -n "${OPENAI_API_KEY}" ]; then
            sed -i "/\[MODELS.OPENAI\]/,/^\[/ s|API_KEY = \"\"|API_KEY = \"${OPENAI_API_KEY}\"|" config.toml
            log_info "OpenAI API key configured for Perplexica"
        fi
        
        # If Anthropic API key exists in env, add it
        if [ -n "${ANTHROPIC_API_KEY}" ]; then
            sed -i "/\[MODELS.ANTHROPIC\]/,/^\[/ s|API_KEY = \"\"|API_KEY = \"${ANTHROPIC_API_KEY}\"|" config.toml
            log_info "Anthropic API key configured for Perplexica"
        fi
        
        # If Groq API key exists in env, add it
        if [ -n "${GROQ_API_KEY}" ]; then
            sed -i "/\[MODELS.GROQ\]/,/^\[/ s|API_KEY = \"\"|API_KEY = \"${GROQ_API_KEY}\"|" config.toml
            log_info "Groq API key configured for Perplexica"
        fi
        
        log_success "Perplexica configured successfully"
    else
        log_info "Perplexica config.toml already exists - skipping configuration"
    fi
    
    cd "$PROJECT_ROOT"
else
    log_info "Perplexica not selected - skipping setup"
fi

exit 0
