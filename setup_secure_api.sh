#!/bin/bash

# 🔒 Secure API Key Setup Script
# This script helps you set up your API keys securely

echo "🔒 Mindscape Flutter - Secure API Setup"
echo "======================================="
echo ""

# Check if template exists
if [ ! -f "test_gemini_terminal.template.dart" ]; then
    echo "❌ Template file not found!"
    exit 1
fi

# Check if the unsafe file exists
if [ -f "test_gemini_terminal.dart" ]; then
    echo "⚠️  Found existing test_gemini_terminal.dart"
    echo "   This file may contain exposed API keys!"
    echo ""
    read -p "Do you want to replace it with the secure template? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp test_gemini_terminal.template.dart test_gemini_terminal.dart
        echo "✅ Replaced with secure template"
    else
        echo "⚠️  Keeping existing file - please update it manually"
    fi
else
    # Create from template
    cp test_gemini_terminal.template.dart test_gemini_terminal.dart
    echo "✅ Created test_gemini_terminal.dart from template"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Edit test_gemini_terminal.dart and replace YOUR_GEMINI_API_KEY_HERE"
echo "2. Or set environment variables:"
echo "   export GEMINI_API_KEY=\"your-actual-key\""
echo "   export PROJECT_NUMBER=\"your-project-number\""
echo ""
echo "🛡️  Security Notes:"
echo "   • test_gemini_terminal.dart is now in .gitignore"
echo "   • Never commit files with actual API keys"
echo "   • Use environment variables when possible"
echo "   • The template file is safe to commit"
echo ""
echo "🚀 Run: dart test_gemini_terminal.dart"