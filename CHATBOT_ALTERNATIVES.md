# Chatbot Alternatives & Adaptive Features Implementation Guide

## Overview
This document outlines multiple chatbot alternatives to Google Dialogflow and explains how to implement adaptive features with conversation memory for your mood tracking app.

## 🔄 Chatbot Alternative Solutions

### 1. OpenAI GPT Integration (Recommended)
**Pros:**
- Natural conversation flow
- Excellent context understanding
- Easy fine-tuning with user data
- Better memory management
- Multilingual support (Indonesian + English)

**Cons:**
- Requires internet connection
- Pay-per-use costs
- API dependency

**Implementation:**
```dart
// Already created: lib/data/services/openai_chat_service.dart
final chatService = OpenAIChatService(apiKey: 'your-openai-key');
final response = await chatService.sendMessage(
  'I feel stressed about my part-time job',
  conversationHistory: previousMessages,
  recentMoods: moodHistory,
);
```

### 2. Local LLM Solutions
**Ollama + Phi-3 Mini (Best for privacy)**
```yaml
# Add to pubspec.yaml
dependencies:
  flutter_ollama: ^0.1.0
```

**Setup:**
1. Install Ollama on your server/device
2. Pull a suitable model: `ollama pull phi3:mini`
3. Use HTTP API calls to localhost

### 3. Firebase ML + Custom Intents
**Pros:**
- Google ecosystem integration
- Serverless functions
- Good for rule-based responses

**Implementation Structure:**
```
Firebase Functions:
├── mood-response/
├── crisis-detection/
├── context-analysis/
└── conversation-flow/
```

### 4. Rasa Open Source
**Best for complete control:**
```yaml
# Rasa setup
version: "3.1"
pipeline:
  - name: WhitespaceTokenizer
  - name: LexicalSyntacticFeaturizer
  - name: CountVectorsFeaturizer
  - name: DIETClassifier
```

## 🚀 Adaptive Features Implementation

### Rush Hour Mode
The system automatically detects when users need quick interactions:

```dart
// Auto-enable rush hour based on user patterns
if (currentHour >= 7 && currentHour <= 9) { // Morning rush
  chatService.enableRushHour(duration: Duration(hours: 2));
}
```

### Data Storage & Memory Architecture

```
Local Storage (Hive):
├── mood_entries (persistent mood history)
├── conversations (chat memory)
├── user_context (behavioral patterns)
└── training_data (for fine-tuning)

Cloud Sync (Optional):
├── Firebase Firestore
├── User anonymized data
└── ML training datasets
```

### Conversation Memory System

The chatbot remembers:
1. **Recent conversations** (last 20 messages)
2. **Mood patterns** (7-day history)
3. **User preferences** (interaction style)
4. **Context tags** (location, activity, time)
5. **Behavioral patterns** (active hours, triggers)

## 📊 Fine-tuning Data Generation

Your app automatically generates training data:

```dart
// Generate training data for better responses
final trainingData = await chatService.generateFineTuningData(
  conversations: conversationHistory,
  moodHistory: moodEntries,
);

// Export for fine-tuning
await exportTrainingData(trainingData, 'training-data.jsonl');
```

**Training Data Format:**
```jsonl
{"prompt": "I'm stressed about my thesis deadline", "completion": "Aku ngerti deadline thesis itu pressure banget. Udah berapa lama kamu working on this? Maybe we can break it down into smaller tasks? 📚"}
{"prompt": "Work is exhausting today", "completion": "Sounds like tough day at work. Kalo udah cape gini, penting banget untuk rest ya. How many hours kamu kerja hari ini?"}
```

## 🔧 Implementation Steps

### Step 1: Setup Dependencies
```yaml
dependencies:
  # Chat services
  http: ^1.1.2
  dio: ^5.4.0
  
  # Local storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # State management
  provider: ^6.1.1
```

### Step 2: Initialize Services
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(MoodEntryAdapter());
  Hive.registerAdapter(ConversationContextAdapter());
  
  // Initialize chat service
  final chatService = AdaptiveChatService();
  await chatService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => chatService),
      ],
      child: MyApp(),
    ),
  );
}
```

### Step 3: Integrate Adaptive UI
```dart
// Use the adaptive mood input widget
class MoodTrackingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mood Check')),
      body: Column(
        children: [
          AdaptiveMoodInput(), // Auto-switches between rush/normal mode
          Expanded(child: ConversationView()),
        ],
      ),
    );
  }
}
```

## 📈 Analytics & Insights

Track user patterns for better adaptation:

```dart
class MoodAnalytics {
  // Identify rush hour patterns
  static List<TimeRange> findRushHours(List<MoodEntry> entries) {
    final hourCounts = <int, int>{};
    for (final entry in entries) {
      hourCounts[entry.timestamp.hour] = (hourCounts[entry.timestamp.hour] ?? 0) + 1;
    }
    // Return most active hours
  }
  
  // Detect mood triggers
  static List<String> findMoodTriggers(List<MoodEntry> entries) {
    // Analyze notes for common negative mood triggers
  }
  
  // Conversation pattern analysis
  static UserBehaviorPattern analyzeUserBehavior(
    List<ChatMessage> conversations,
    List<MoodEntry> moods,
  ) {
    // Return behavioral insights for personalization
  }
}
```

## 🔒 Privacy & Security

### Data Handling
- All sensitive data stays local (Hive storage)
- Only anonymized patterns sent to external APIs
- User controls what data is shared
- Automatic data expiration (older than 6 months)

### Crisis Detection
```dart
class CrisisDetector {
  static bool detectCrisis(String message, List<MoodEntry> recentMoods) {
    final crisisKeywords = ['suicide', 'bunuh diri', 'self harm', 'cutting'];
    final lowMoodStreak = recentMoods.where((m) => m.moodType.value <= 2).length;
    
    return crisisKeywords.any((keyword) => 
        message.toLowerCase().contains(keyword)) || 
        lowMoodStreak >= 5;
  }
}
```

## 🚦 Fallback Strategy

If all external services fail:
1. **Rule-based responses** (pre-defined templates)
2. **Local pattern matching** (keyword detection)
3. **Mood-specific suggestions** (hardcoded advice)
4. **Crisis resource links** (UGM counseling contacts)

## 📱 Usage Example

```dart
// Quick mood registration (rush hour)
final response = await chatService.registerQuickMood(
  MoodLevel.bad,
  note: 'Tired from work',
);
// -> "Capek abis kerja ya? Rest dulu, you deserve it 💙"

// Full conversation
final response = await chatService.sendMessage(
  'I have a big presentation tomorrow and I\'m nervous',
  metadata: {'context': 'academic_stress'},
);
// -> "Presentation anxiety is totally normal! Udah prepare dari kapan? Let's think through this together..."
```

## 🎯 Recommended Implementation Order

1. **Week 1**: Set up OpenAI integration + basic conversation memory
2. **Week 2**: Implement adaptive UI with rush hour mode
3. **Week 3**: Add local LLM fallback + crisis detection
4. **Week 4**: Fine-tune with collected user data
5. **Week 5**: Analytics dashboard + behavioral insights

This approach gives you multiple robust alternatives to Dialogflow while providing the adaptive features and conversation memory you need for an effective mood tracking app.