import 'package:flutter/material.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_colors.dart';

class PreinspectionAgentApp extends StatelessWidget {
  const PreinspectionAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IBima Assist — Pre-Inspection Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        // Material 3 defaults the calendar to a washed-out lavender surface,
        // which read as "dull" against the rest of the app. Paint it in the
        // brand blue instead so date pickers match every other screen.
        datePickerTheme: DatePickerThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          headerBackgroundColor: AppColors.bgPageTitle,
          headerForegroundColor: AppColors.textWhite,
          dividerColor: AppColors.borderInput,
          dayForegroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.textWhite
                : AppColors.textPrimary,
          ),
          dayBackgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primary
                : null,
          ),
          todayForegroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.textWhite
                : AppColors.primary,
          ),
          todayBackgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primary
                : null,
          ),
          todayBorder: const BorderSide(color: AppColors.primary),
          yearForegroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.textWhite
                : AppColors.textPrimary,
          ),
          yearBackgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primary
                : null,
          ),
          confirmButtonStyle: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
          cancelButtonStyle: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          ),
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
