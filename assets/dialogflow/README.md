# Dialogflow JSON Files

## Struktur untuk Dialogflow Integration

### 📁 Safe untuk di-commit (public configuration):
```
assets/dialogflow/
├── agent_config.json          # Agent metadata (name, language, timezone)
├── intents/
│   ├── mood_greeting.json     # Intent untuk greeting mood tracking
│   ├── mood_sad.json          # Intent untuk handle sedih/stress
│   ├── mood_happy.json        # Intent untuk handle senang
│   ├── burnout_support.json   # Intent untuk burnout support
│   ├── crisis_detection.json  # Intent untuk crisis detection
│   └── small_talk.json        # Intent untuk casual conversation
└── entities/
    ├── mood_types.json        # Entity untuk tipe mood
    ├── side_gigs.json         # Entity untuk jenis side gig
    └── time_expressions.json  # Entity untuk waktu (pagi, siang, malam)
```

### 🚫 JANGAN commit (credentials):
- `dialogflow-credentials.json` - Service account credentials
- `service-account-key.json` - Google Cloud service account
- `google-services.json` - Firebase config (Android)
- `GoogleService-Info.plist` - Firebase config (iOS)

## Cara penggunaan:

1. **Agent Configuration** → `assets/dialogflow/agent_config.json`
2. **Individual Intents** → `assets/dialogflow/intents/[intent-name].json`  
3. **Entities** → `assets/dialogflow/entities/[entity-name].json`
4. **Service Account Key** → `lib/core/config/dialogflow_credentials.json` (gitignored)

## Setup Instructions:

1. Export agent dari Dialogflow Console
2. Extract ZIP file
3. Copy intents ke `assets/dialogflow/intents/`
4. Copy entities ke `assets/dialogflow/entities/`
5. Copy agent.json ke `assets/dialogflow/agent_config.json`
6. Download service account key → `lib/core/config/dialogflow_credentials.json`