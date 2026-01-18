#!/bin/bash
# Report for speech

echo
echo "================================= Speech Stack ========================="
echo
echo "=== Whisper (Speech-to-Text) ==="
echo "Host: ${WHISPER_HOSTNAME:-<hostname_not_set>}"
echo "API Endpoint: https://${WHISPER_HOSTNAME:-<hostname_not_set>}/v1/audio/transcriptions"
echo "Auth User: ${WHISPER_AUTH_USER:-<not_set_in_env>}"
echo "Model: ${WHISPER_MODEL:-Systran/faster-distil-whisper-large-v3}"
echo "Internal Access (no auth): http://faster-whisper:8000"
echo
echo "=== OpenedAI-Speech (Text-to-Speech) ==="
echo "Host: ${TTS_HOSTNAME:-<hostname_not_set>}"
echo "API Endpoint: https://${TTS_HOSTNAME:-<hostname_not_set>}/v1/audio/speech"
echo "Auth User: ${TTS_AUTH_USER:-<not_set_in_env>}"
echo "Internal Access (no auth): http://openedai-speech:8000/v1/audio/speech"
echo
echo "Note: External access requires Basic Auth. Internal access from n8n is auth-free."
echo "Note: Services are CPU-optimized for VPS"
