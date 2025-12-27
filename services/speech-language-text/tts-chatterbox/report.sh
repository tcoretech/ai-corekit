#!/bin/bash
# Report for tts-chatterbox

echo
echo "================================= TTS Chatterbox ======================"
echo
echo "🎙️ State-of-the-Art Text-to-Speech with Emotion Control"
echo
echo "Host: ${CHATTERBOX_HOSTNAME:-<hostname_not_set>}"
echo "API Key: ${CHATTERBOX_API_KEY:-<not_set_in_env>}"
echo "Device: ${CHATTERBOX_DEVICE:-cpu}"
echo "Emotion Level: ${CHATTERBOX_EXAGGERATION:-0.5} (0.25-2.0)"
echo
echo "Access:"
echo "  External (HTTPS): https://${CHATTERBOX_HOSTNAME:-<hostname_not_set>}"
echo "  Internal (Docker): http://chatterbox-tts:4123"
echo
echo "Web UI Access:"  
echo "  Frontend: https://${CHATTERBOX_FRONTEND_HOSTNAME:-<hostname_not_set>}"
echo
echo "API Endpoints:"
echo "  OpenAI Compatible: POST /v1/audio/speech"
echo "  Health Check: GET /health"
echo "  Voices List: GET /v1/voices"
echo "  Voice Clone: POST /v1/voice/clone"
echo
echo "n8n Integration:"
echo "  Use HTTP Request node with URL: http://chatterbox-tts:4123/v1/audio/speech"
echo "  Add header: X-API-Key: \${CHATTERBOX_API_KEY}"
echo
echo "Voice Cloning:"
echo "  1. Place 10-30 second audio samples in: ./shared/tts/voices/"
echo "  2. Supported formats: wav, mp3, ogg, flac"
echo "  3. Use voice ID in API calls"
echo
echo "Performance:"
echo "  CPU Mode: ~5-10 seconds per sentence"
echo "  GPU Mode: <1 second per sentence (set CHATTERBOX_DEVICE=cuda)"
echo
echo "Documentation: https://github.com/travisvn/chatterbox-tts-api"
echo "Model Info: https://www.resemble.ai/chatterbox/"
