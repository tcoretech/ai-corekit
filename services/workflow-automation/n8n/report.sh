#!/bin/bash
# Report for n8n

echo
echo "================================= n8n ================================="
echo
echo "Host: ${N8N_HOSTNAME:-<hostname_not_set>}"
echo
echo "================================= n8n Task Runner ================================="
log_success "Python Task Runner: ENABLED"
echo "  📦 Native Python execution in n8n Code nodes"
echo "  ⚡ Better performance than Pyodide (10-20x faster)"
echo "  📚 Supports: pandas, numpy, requests, scikit-learn (via custom image)"
echo "  ⚠️  Breaking Change: Use item[\"json\"] instead of item.json"
echo "  📖 Migration Guide: See README.md for syntax changes"
