// import 'package:behavior_api/behavior_api.dart';
import 'package:behavior_api/behavior_api.dart';
import 'package:code_lfa/config.dart';
import 'package:code_lfa/generated/l10n.dart';
import 'package:code_lfa/terminal_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:global_repository/global_repository.dart';
import 'package:settings/settings.dart';

// Notice: behavior will submit Device

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 隐藏系统 UI
  // Hide system UI
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [
      // SystemUiOverlay.top,
      // SystemUiOverlay.bottom,
    ],
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  RuntimeEnvir.initEnvirWithPackageName('com.nightmare.code');
  await initSettingStore(RuntimeEnvir.configPath);
  runApp(const CodeLFA());
  initApi('Code LFA', Config.versionName);
}

/// 应用程序的主入口Widget
class CodeLFA extends StatelessWidget {
  /// 应用根组件
  const CodeLFA({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Code LFA',
      theme: ThemeData(
        colorSchemeSeed: Colors.primaries[3],
      ),
      // locale: const Locale('zh', 'CN'),
      // locale: const Locale('en'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: const TerminalPage(),
    );
  }
}
