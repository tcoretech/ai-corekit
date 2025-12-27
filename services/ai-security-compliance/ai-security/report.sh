#!/bin/bash
# Report for ai-security

echo
echo "================================= AI Security Suite ==================="
echo
echo "🛡️  LLM Guard (Prompt Injection Protection)"
echo "  Internal API: http://llm-guard:8000"
echo "  API Token: ${LLM_GUARD_TOKEN:-<not_set_in_env>}"
echo
echo "🔐  Microsoft Presidio (GDPR-Compliant PII Handling - English)"
echo "  Analyzer API: http://presidio-analyzer:3000"
echo "  Anonymizer API: http://presidio-anonymizer:3000"
echo "  Min Score: ${PRESIDIO_MIN_SCORE:-0.5}"
echo
echo "🌍  Flair NER (German/Multi-language PII Detection)"
echo "  Internal API: http://flair-pii:8000"
echo "  Models: de-ner-large (German), ner-large (English)"
echo "  Accuracy: 95%+ for German names/locations"
echo
echo "📚  n8n Integration Examples:"
echo
echo "  LLM Guard - Pre-processing check:"
echo "    POST http://llm-guard:8000/analyze/prompt"
echo "    Headers: { \"Authorization\": \"Bearer \${LLM_GUARD_TOKEN}\" }"
echo "    Body: { \"prompt\": \"user input text\" }"
echo
echo "  Presidio - PII Detection (English):"
echo "    POST http://presidio-analyzer:3000/analyze"
echo "    Body: { \"text\": \"...\", \"language\": \"en\" }"
echo
echo "  Flair - PII Detection (German/Multi-language):"
echo "    POST http://flair-pii:8000/analyze"
echo "    Body: { \"text\": \"...\", \"language\": \"de\" }"
echo
echo "  Presidio/Flair - Anonymization:"
echo "    Presidio: POST http://presidio-anonymizer:3000/anonymize"
echo "    Flair: POST http://flair-pii:8000/anonymize"
echo
echo "💡 Workflow Patterns:"
echo "  English: User Input → LLM Guard → Presidio → LLM → Output"
echo "  German: User Input → LLM Guard → Flair → LLM → Output"
echo "  Hybrid: Use Flair for NER + Presidio for patterns"
echo
echo "Documentation:"
echo "  LLM Guard: https://llm-guard.com/docs"
echo "  Presidio: https://microsoft.github.io/presidio"
echo "  Flair: https://github.com/flairNLP/flair"
