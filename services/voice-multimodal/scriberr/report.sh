#!/bin/bash
# Report for scriberr

echo
echo "================================= Scriberr ============================"
echo
echo "🎙️ AI Audio Transcription with Speaker Diarization"
echo
echo "Host: ${SCRIBERR_HOSTNAME:-<hostname_not_set>}"
echo "Whisper Model: ${SCRIBERR_WHISPER_MODEL:-base}"
echo "Speaker Detection: ${SCRIBERR_SPEAKER_DIARIZATION:-true}"
echo
echo "Access:"
echo "  External (HTTPS): https://${SCRIBERR_HOSTNAME:-<hostname_not_set>}"
echo "  Internal API: http://scriberr:8080/api"
echo
echo "Authentication:"
echo "  ✓ Scriberr has its own user management"
echo "  ✓ Create your account on first access"
echo "  ✓ API keys can be generated in the UI"
echo
echo "API Endpoints:"
echo "  Upload: POST http://scriberr:8080/api/upload"
echo "  Transcripts: GET http://scriberr:8080/api/transcripts"
echo "  Summary: POST http://scriberr:8080/api/summary"
echo
echo "n8n Integration:"
echo "  1. Upload audio via HTTP Request node to /api/upload"
echo "  2. Poll /api/transcripts/{id} for results"
echo "  3. Shared folder: /data/shared/audio"
echo
echo "Model Info:"
echo "  - tiny: ~1GB RAM, fastest, lower quality"
echo "  - base: ~1.5GB RAM, good balance (default)"
echo "  - small: ~3GB RAM, better quality"
echo "  - medium: ~5GB RAM, high quality"
echo "  - large: ~10GB RAM, best quality"
echo
echo "First start may take 2-5 minutes to download models."
echo "Documentation: https://github.com/rishikanthc/Scriberr"
