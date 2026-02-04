import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/adaptive_provider.dart';
import '../core/constants/app_constants.dart';
import '../domain/entities/adaptive_context.dart';
import 'themes/app_theme.dart';
import 'router/app_router.dart';

/// Main application widget that handles routing and theme management
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdaptiveProvider>(
      builder: (context, adaptiveProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          
          // Adaptive theme based on user context
          theme: AppTheme.getTheme(adaptiveProvider.currentContext),
          
          // Navigation
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: AppRouter.splashRoute,
          
          // Global scaffold messenger for snackbars
          scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          
          // Accessibility
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(_getAdaptiveTextScale(adaptiveProvider.currentContext)),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }

  double _getAdaptiveTextScale(AdaptiveContext context) {
    // Increase text scale when user is stressed for better readability
    if (context.stressLevel.value >= StressLevel.high.value) {
      return 1.1;
    }
    return 1.0;
  }
}