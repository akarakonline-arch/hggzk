import 'package:rezmateportal/core/bloc/locale/locale_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:rezmateportal/core/bloc/theme/theme_bloc.dart';
import 'package:rezmateportal/core/bloc/theme/theme_state.dart';
import 'package:rezmateportal/core/localization/app_localizations.dart';
import 'package:rezmateportal/core/localization/locale_manager.dart';
import 'package:rezmateportal/routes/app_router.dart';
import 'package:rezmateportal/injection_container.dart' as di;
import 'package:rezmateportal/core/bloc/app_bloc.dart';
import 'package:rezmateportal/services/navigation_service.dart';
// Removed settings bloc dependency
import 'package:rezmateportal/core/theme/app_theme.dart';
import 'package:rezmateportal/services/message_service.dart';

class HggzkPortalApp extends StatelessWidget {
  const HggzkPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // TypingIndicatorProvider removed; ChatBloc maintains typingUsers state
        ...AppBloc.providers,
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        bloc: AppBloc.theme,
        builder: (context, themeState) {
          return BlocBuilder<LocaleCubit, Locale>(
            bloc: AppBloc.locale,
            builder: (context, localeState) {
              return MaterialApp.router(
                title: 'rezmateportal',
                debugShowCheckedModeBanner: false,
                theme: ThemeData.light(),
                darkTheme: ThemeData.dark(),
                themeMode: themeState.themeMode,
                locale: localeState,
                scaffoldMessengerKey: MessageService.scaffoldMessengerKey,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: LocaleManager.supportedLocales,
                routerConfig: AppRouter.build(context),
                builder: (context, child) {
                  AppTheme.init(context, mode: themeState.themeMode);
                  return child!;
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Settings feature removed: hardcode defaults
