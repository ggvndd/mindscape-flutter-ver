# Mindscape Flutter - Mood Tracker Adaptif untuk Mahasiswa UGM

Aplikasi mobile mood tracker adaptif berbasis chatbot untuk mendukung manajemen burnout pada mahasiswa UGM yang memiliki side gig/part-time job.

## 🎯 Tujuan Penelitian

Aplikasi ini dikembangkan sebagai bagian dari skripsi akhir IT di Universitas Gadjah Mada dengan fokus:

- **Target User**: Mahasiswa usia 18-25 tahun dengan side gig minimal 10 jam/minggu
- **Problem**: Burnout akibat double burden (kuliah + kerja), jadwal tak teratur, algorithmic pressure
- **Solution**: Self-awareness dan manajemen burnout melalui mood tracking adaptif dan chatbot empati

## 🔬 Metodologi Evaluasi

### Metrics yang Diukur:
1. **TSR-CC (Task Success Rate - Cognitive Constraints)**: Keberhasilan mood logging dalam <15 detik
2. **ERI (Emotional Response Index)**: Tingkat empati dan dukungan dari chatbot (Likert 1-5)  
3. **PEI (Personalization Effectiveness Index)**: Relevansi fitur adaptif terhadap konteks user

### Pendekatan UX Research:
- **User-Centered Design (UCD)** iteratif
- **Cognitive load reduction** untuk high-stress situations
- **Privacy-first** approach dengan informed consent

## 🚀 Fitur Utama

### 1. Quick Mood Logging (<15 detik)
- **Adaptive Input**: Emoji picker, voice input, atau text - switch otomatis berdasarkan konteks
- **Context Detection**: Waktu, motion state, stress level history
- **TSR-CC Timer**: Real-time measurement untuk evaluasi performa

### 2. Dashboard Minimalis & Adaptif
- **Normal Mode**: Today's mood + 7-day trends + quick actions
- **Stress Mode**: Simplified UI dengan calming colors, minimal cognitive load
- **Dark Mode**: Auto-enable untuk late night atau high stress

### 3. Chatbot Personal (Dialogflow ES)
- **Indonesian Natural Language**: Bahasa gaul yang relatable ("nih", "banget", "yuk")
- **Empathetic Responses**: Context-aware dari mood history
- **Crisis Detection**: Redirect ke konselor UGM/hotline untuk keadaan darurat
- **Memory**: Ingat percakapan sebelumnya untuk personalisasi

### 4. Adaptive Behavior Engine
- **Context-Aware UI**: Menyesuaikan tampilan berdasarkan stress level, waktu, motion
- **Smart Input Method**: Voice saat mobile/malam, emoji saat stressed, text untuk ekspresi detail
- **Personalized Insights**: "Kamu sering drop setelah shift malam ya?"

### 5. Privacy & Ethics Compliance
- **Informed Consent**: Transparent data handling
- **Local-First Storage**: Hive untuk offline capability
- **Optional Cloud Sync**: User-controlled dengan encryption
- **Crisis Support Integration**: Professional resources untuk situasi emergency

## 🏗️ Arsitektur Aplikasi

### State Management
```
Provider Pattern:
- MoodProvider: Mood tracking & quick logging
- AdaptiveProvider: Context awareness & UI adaptation  
- ChatProvider: Dialogflow ES integration
- UserProvider: Profile & preferences management
```

### Data Layer
```
Repository Pattern:
- Local Storage: Hive (offline-first)
- Cloud Sync: Optional Firebase/Supabase
- External APIs: Dialogflow ES, Speech-to-Text
```

### Adaptive Controller
```
Context Detection:
- Time of day patterns
- Device motion state
- Mood history analysis
- User work schedule
- Stress level calculation
```

## 📱 User Journey Flow

```
Onboarding Flow:
Welcome → Privacy Consent → Profile Setup → Adaptive Preferences

Main App Flow:
Home Dashboard ⇄ Quick Log ⇄ Chatbot ⇄ Trends
     │              │          │         
     │              │          └─ Voice Input (adaptive)
     │              └─ Stress Mode UI (simplified)
     └─ Focus Mode / Crisis Support (when needed)
```

## 🛠️ Tech Stack

### Core Dependencies
- **Flutter SDK**: ^3.10.7
- **State Management**: Provider ^6.1.1  
- **Local Storage**: Hive ^4.0.0 (offline-first)
- **HTTP/API**: Dio ^5.4.0 untuk Dialogflow ES
- **Speech**: speech_to_text ^6.5.1, flutter_tts ^3.8.3
- **Charts**: fl_chart ^0.65.0 untuk mood trends
- **Sensors**: sensors_plus ^4.0.2 untuk context detection

### External Services
- **Dialogflow ES**: Natural Language Understanding untuk chatbot Indonesia
- **Google Speech-to-Text**: Voice input processing
- **Firebase Analytics**: Optional, privacy-compliant usage metrics

## 🔧 Development Setup

### Prerequisites
- Flutter SDK ^3.10.7
- Dart SDK ^3.10.7
- Android Studio / VS Code
- Google Cloud Account (untuk Dialogflow ES)

### Installation
```bash
# Clone repository
git clone <repository-url>
cd mindscape_flutter

# Install dependencies
flutter pub get

# Generate Hive adapters (jika ada)
flutter packages pub run build_runner build

# Run app
flutter run
```

### Dialogflow ES Setup
1. Create Google Cloud Project
2. Enable Dialogflow ES API
3. Create agent dengan Indonesian language support
4. Train dengan mood-related intents
5. Configure credentials dalam app

### Testing
```bash
# Unit tests
flutter test

# Integration tests (TSR-CC, user journey)
flutter test integration_test/

# Generate test coverage
flutter test --coverage
```

## 📊 Evaluasi & Metrics

### TSR-CC Measurement
```dart
// Automatic timing untuk mood logging tasks
TSRCCTimer().startTask('quick_mood_log');
// ... user interaction
final score = TSRCCTimer().completeTask('quick_mood_log', successful);
```

### ERI Evaluation
```dart
// Post-chatbot interaction survey
ERILogger().logERIEvaluation(
  empathyScore: 4, // 1-5 Likert
  helpfulnessScore: 5,
  overallSatisfaction: 4,
);
```

### PEI Tracking
```dart
// Log adaptive feature effectiveness
PEILogger().logAdaptiveFeature(
  featureName: 'voice_input_switch',
  relevanceScore: 5, // User rating
  userContext: 'high_stress_evening',
);
```

## 🔒 Privacy & Ethics

### Data Protection
- **Local-first**: Mood data stored locally dengan Hive encryption
- **Minimal Cloud**: Hanya sync jika user explicitly opt-in
- **Anonymization**: Analytics data tidak contain PII
- **Right to Delete**: Complete data deletion capability

### Crisis Intervention
- **Keyword Detection**: Automatic detection untuk crisis signals
- **Professional Referral**: Direct link ke konseling UGM & hotline nasional
- **No Medical Claims**: Clear disclaimer bahwa ini bukan medical advice

### Consent Management  
- **Granular Permissions**: Separate consent untuk analytics, cloud sync, voice recording
- **Transparent Disclosure**: Clear explanation tentang data usage
- **Withdraw Anytime**: Easy opt-out dari semua data collection

## 📈 Expected Research Outcomes

### Quantitative Metrics
- **TSR-CC Target**: >80% success rate untuk mood logging <15 detik
- **ERI Target**: Average 4+ dari 5 untuk empathy perception
- **PEI Target**: 75%+ relevance untuk adaptive features

### Qualitative Insights
- User acceptance terhadap adaptive UI behavior
- Effectiveness dari Indonesian empathetic chatbot
- Impact pada daily mood awareness & burnout management

## 🤝 Contributing

Untuk research collaboration atau technical contributions:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`) 
5. Open Pull Request

## 📝 License & Citation

Jika menggunakan research findings atau code untuk publikasi akademis, silakan cite:

```
[Author]. (2026). "Adaptive Mood Tracking Application for University Students 
with Side Gigs: A UCD Approach for Burnout Management." 
Universitas Gadjah Mada Final Thesis.
```

## 📧 Contact

- **Research**: [Email peneliti]
- **Technical Issues**: GitHub Issues
- **UGM Counseling**: +62274513163 (24/7)
- **Crisis Hotline**: 119

---

**Disclaimer**: Aplikasi ini untuk research & educational purposes. Bukan pengganti konsultasi medis profesional. Jika mengalami crisis mental health, segera hubungi professional atau hotline yang tersedia.

## 🙏 Acknowledgments

Terima kasih untuk:
- Dosen pembimbing skripsi UGM
- Mahasiswa UGM yang berpartisipasi dalam user testing  
- Flutter & Dialogflow communities
- Open source contributors yang dependencies-nya kita pakai

**Mindscape** - *Empowering young gig workers through adaptive mood awareness* 💙✨
