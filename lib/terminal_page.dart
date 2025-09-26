import 'package:code_lfa/terminal_controller.dart';
import 'package:code_lfa/terminal_theme.dart';
import 'package:code_lfa/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:global_repository/global_repository.dart';
import 'package:xterm/xterm.dart';

/// 终端页面组件，提供交互式终端界面，包含终端视图和加载进度显示功能
///
/// Terminal page, providing an interactive terminal interface, which
/// includes a terminal view and loading progress display function
class TerminalPage extends StatefulWidget {
  /// 终端页面
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

/// 终端页面状态类，管理终端视图的显示和交互逻辑
///
/// Terminal page state class, manages the display and interaction logic of terminal view
///
/// 主要功能包括:
/// - 使用GetX管理终端控制器状态
/// - 控制终端视图的显示/隐藏
/// - 处理返回按钮事件(发送Ctrl+C中断信号)
/// - 显示加载进度条和状态信息
///
/// Main functions include:
/// - Uses GetX to manage terminal controller state
/// - Controls terminal view visibility
/// - Handles back button event (sends Ctrl+C interrupt signal)
/// - Displays loading progress bar and status information
class _TerminalPageState extends State<TerminalPage> {
  /// 终端控制器实例，通过GetX进行状态管理
  ///
  /// Terminal controller instance, managed by GetX
  HomeController controller = Get.put(HomeController());

  /// 终端主题配置
  ///
  /// Terminal theme configuration
  ManjaroTerminalTheme terminalTheme = ManjaroTerminalTheme();

  /// 控制终端视图的可见性，默认为false(调试模式下为true)
  ///
  /// Controls terminal view visibility, default is false (true in debug mode)
  bool visible = false || kDebugMode;

  /// 构建终端页面布局
  ///
  /// Builds terminal page layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: visible
          ? terminalTheme.background
          : Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: PopScope(
          onPopInvokedWithResult: (didPop, result) {
            controller.pseudoTerminal!.writeString('\x03');
            Get.back<dynamic>();
          },
          child: GestureDetector(
            onTap: () {
              visible = !visible;
              setState(() {});
            },
            behavior: HitTestBehavior.translucent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 终端视图容器
                // Terminal view container
                Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Visibility(
                    visible: visible,
                    // 忽略指针事件，防止终端视图拦截触摸输入
                    // Ignore pointer events to prevent terminal view from
                    // intercepting touch input
                    child: AbsorbPointer(
                      absorbing: false,
                      child: TerminalView(
                        controller.terminal,
                        theme: ManjaroTerminalTheme(),
                      ),
                    ),
                  ),
                ),
                loadProgressIndicator(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 加载进度指示器及其约束
  /// 
  /// Loading progress indicator and its constraints
  Widget loadProgressIndicator(BuildContext context) {
    return Center(
      child: Material(
        borderRadius: BorderRadius.circular(12.w),
        color: Theme.of(context).colorScheme.surface,
        child: SizedBox(
          width: 300.w,
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Center(
                  child: RepaintBoundary(
                    child: LoadingProgress(),
                  ),
                ),
                SizedBox(height: 12.w),
                GetBuilder<HomeController>(
                  builder: (controller) {
                    return Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 5.w,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha((0.2 * 255).round()),
                                borderRadius: BorderRadius.circular(3.w),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 5.w,
                              width: 300.w * controller.progress,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(3.w),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.w),
                        Text(
                          controller.currentProgress.trim(),
                          style: TextStyle(
                            fontSize: 12.w,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
