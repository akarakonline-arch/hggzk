import 'package:hggzkportal/core/bloc/locale/locale_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hggzkportal/core/bloc/theme/theme_bloc.dart';
import 'package:hggzkportal/core/bloc/theme/theme_state.dart';
import 'package:hggzkportal/core/localization/app_localizations.dart';
import 'package:hggzkportal/core/localization/locale_manager.dart';
import 'package:hggzkportal/routes/app_router.dart';
import 'package:hggzkportal/injection_container.dart' as di;
import 'package:hggzkportal/core/bloc/app_bloc.dart';
import 'package:hggzkportal/services/navigation_service.dart';
// Removed settings bloc dependency
import 'package:hggzkportal/core/theme/app_theme.dart';
import 'package:hggzkportal/services/message_service.dart';

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
                title: 'hggzkportal',
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
