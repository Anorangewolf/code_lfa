import 'dart:ui';

import 'package:xterm/xterm.dart';

/// Manjaro Linux 风格的终端主题
///
/// 该类继承自 [TerminalTheme]，提供了 Manjaro Linux 风格的终端配色方案。
/// 包含了光标颜色、选择区域颜色、前景色、背景色以及标准16色终端颜色。
/// 此外还包含了搜索高亮相关的颜色配置。
///
/// 颜色值基于 Manjaro Linux 默认终端配色方案。
class ManjaroTerminalTheme extends TerminalTheme {
  /// 创建 Manjaro Linux 风格的终端主题
  ManjaroTerminalTheme({
    super.cursor = const Color(0xaaf6f5f4),
    super.selection = const Color(0XAAAEAFAD),
    super.foreground = const Color(0xffe5e5e5),
    super.background = const Color(0xff1c1c1e),
    super.black = const Color(0xff241f31),
    super.white = const Color(0xffc0bfbc),
    super.red = const Color(0xffc01c28),
    super.green = const Color(0xff2ec27e),
    super.yellow = const Color(0xfff5c211),
    super.blue = const Color(0xff1e78e4),
    super.magenta = const Color(0xff9841bb),
    super.cyan = const Color(0xff0ab9dc),
    super.brightBlack = const Color(0xff5e5c64),
    super.brightRed = const Color(0xffed333b),
    super.brightGreen = const Color(0xff57e389),
    super.brightYellow = const Color(0xfff8e45c),
    super.brightBlue = const Color(0xff51a1ff),
    super.brightMagenta = const Color(0xffc061cb),
    super.brightCyan = const Color(0xff4fd2fd),
    super.brightWhite = const Color(0xfff6f5f4),
    super.searchHitBackground = const Color(0XFF000000),
    super.searchHitBackgroundCurrent = const Color(0XFF31FF26),
    super.searchHitForeground = const Color(0XFF000000),
  });
}
