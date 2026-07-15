#!/usr/bin/env python3
import os
from pathlib import Path
from urllib.request import urlopen, Request
import json

# Load .env if present
try:
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).parent.parent / '.env')
except Exception:
    pass

api_key = os.getenv('GEMINI_API_KEY')
if not api_key:
    print('GEMINI_API_KEY not set')
    raise SystemExit(1)

url = f'https://generativelanguage.googleapis.com/v1beta/models?key={api_key}'
req = Request(url)
try:
    with urlopen(req, timeout=15) as resp:
        data = resp.read().decode('utf-8')
        j = json.loads(data)
        print('Models list retrieved:')
        for m in j.get('models', []):
            print('-', m.get('name'))
except Exception as e:
    print('Error fetching models:', e)
    raise
