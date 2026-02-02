#!/bin/bash
# Report for python-runner

echo
echo "================================= Python Runner ========================"
echo
echo "Internal Container DNS: python-runner"
echo "Mounted Code Directory: ./python-runner (host) -> /app (container)"
echo "Entry File: /app/main.py"
echo "(Note: Internal-only service with no exposed ports; view output via logs)"
echo "Logs: corekit logs -f python-runner"
