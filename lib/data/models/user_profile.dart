import '../../../domain/entities/adaptive_context.dart';

/// User profile data model
class UserProfile {
  final String id;
  final String nickname;
  final String sideGigType; // 'ojek', 'tutor', 'freelance', 'content_creator', etc.
  final int workHoursPerWeek;
  final int semester;
  final List<int> busyHours; // Hours when typically busy (0-23)
  final AdaptivePreferences adaptivePreferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.nickname,
    required this.sideGigType,
    required this.workHoursPerWeek,
    required this.semester,
    required this.busyHours,
    required this.adaptivePreferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      nickname: json['nickname'],
      sideGigType: json['side_gig_type'],
      workHoursPerWeek: json['work_hours_per_week'],
      semester: json['semester'],
      busyHours: List<int>.from(json['busy_hours']),
      adaptivePreferences: AdaptivePreferences.fromJson(json['adaptive_preferences']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'side_gig_type': sideGigType,
      'work_hours_per_week': workHoursPerWeek,
      'semester': semester,
      'busy_hours': busyHours,
      'adaptive_preferences': adaptivePreferences.toJson(),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  UserProfile copyWith({
    String? nickname,
    String? sideGigType,
    int? workHoursPerWeek,
    int? semester,
    List<int>? busyHours,
    AdaptivePreferences? adaptivePreferences,
  }) {
    return UserProfile(
      id: id,
      nickname: nickname ?? this.nickname,
      sideGigType: sideGigType ?? this.sideGigType,
      workHoursPerWeek: workHoursPerWeek ?? this.workHoursPerWeek,
      semester: semester ?? this.semester,
      busyHours: busyHours ?? this.busyHours,
      adaptivePreferences: adaptivePreferences ?? this.adaptivePreferences,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// User preferences for adaptive behavior
class AdaptivePreferences {
  final bool enableVoiceInput;
  final bool enableAdaptiveThemes;
  final bool enableContextDetection;
  final InputMethod preferredInputMethod;
  final bool allowAnalytics;
  final bool allowCloudSync;

  const AdaptivePreferences({
    required this.enableVoiceInput,
    required this.enableAdaptiveThemes,
    required this.enableContextDetection,
    required this.preferredInputMethod,
    required this.allowAnalytics,
    required this.allowCloudSync,
  });

  factory AdaptivePreferences.defaultSettings() {
    return const AdaptivePreferences(
      enableVoiceInput: true,
      enableAdaptiveThemes: true,
      enableContextDetection: true,
      preferredInputMethod: InputMethod.emoji,
      allowAnalytics: false, // Privacy-first approach
      allowCloudSync: false,
    );
  }

  factory AdaptivePreferences.fromJson(Map<String, dynamic> json) {
    return AdaptivePreferences(
      enableVoiceInput: json['enable_voice_input'],
      enableAdaptiveThemes: json['enable_adaptive_themes'],
      enableContextDetection: json['enable_context_detection'],
      preferredInputMethod: InputMethod.values.firstWhere(
        (method) => method.name == json['preferred_input_method'],
        orElse: () => InputMethod.emoji,
      ),
      allowAnalytics: json['allow_analytics'],
      allowCloudSync: json['allow_cloud_sync'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable_voice_input': enableVoiceInput,
      'enable_adaptive_themes': enableAdaptiveThemes,
      'enable_context_detection': enableContextDetection,
      'preferred_input_method': preferredInputMethod.name,
      'allow_analytics': allowAnalytics,
      'allow_cloud_sync': allowCloudSync,
    };
  }

  AdaptivePreferences copyWith({
    bool? enableVoiceInput,
    bool? enableAdaptiveThemes,
    bool? enableContextDetection,
    InputMethod? preferredInputMethod,
    bool? allowAnalytics,
    bool? allowCloudSync,
  }) {
    return AdaptivePreferences(
      enableVoiceInput: enableVoiceInput ?? this.enableVoiceInput,
      enableAdaptiveThemes: enableAdaptiveThemes ?? this.enableAdaptiveThemes,
      enableContextDetection: enableContextDetection ?? this.enableContextDetection,
      preferredInputMethod: preferredInputMethod ?? this.preferredInputMethod,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      allowCloudSync: allowCloudSync ?? this.allowCloudSync,
    );
  }
}