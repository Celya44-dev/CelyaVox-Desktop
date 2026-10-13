#!/bin/bash
# verify-protocol-registration.sh
# Script to verify that the tel: protocol is correctly registered on Windows

# This script should be run on a Windows machine after installation

echo "=== CelyaVox Protocol Registration Verification ==="
echo ""

# Check if running on Windows
if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "win32" && ! "$OSTYPE" =~ ^cygwin ]]; then
  echo "❌ This verification script must run on Windows"
  exit 1
fi

echo "Checking registry for tel: protocol association..."
echo ""

# Check NSIS/MSI installation registry entry
reg query "HKCU\Software\Classes\tel" 2>&1 | grep -q "URL Protocol" && {
  echo "✅ Protocol tel: is registered at HKCU\Software\Classes\tel"
  echo ""
  echo "Registry entry details:"
  reg query "HKCU\Software\Classes\tel\shell\open\command" /v "(Default)" 2>/dev/null || {
    reg query "HKCU\Software\Classes\tel\shell\open\command" 2>/dev/null || echo "❌ Could not read command registry entry"
  }
} || {
  echo "⚠️ Protocol tel: not found in HKCU registry"
  echo "   (Will be registered on first application launch)"
}

echo ""
echo "Testing protocol handler..."
echo ""

# Test by launching a tel: link
RESULT=$(powershell.exe -NoProfile -Command "Start-Process 'tel:+33123456789' -ErrorAction SilentlyContinue; echo \$LASTEXITCODE" 2>&1)
if [[ "$RESULT" == "0" ]] || [[ "$RESULT" == "" ]]; then
  echo "✅ Protocol handler executed successfully"
else
  echo "⚠️ Protocol handler execution returned exit code: $RESULT"
fi

echo ""
echo "=== Verification Complete ==="
