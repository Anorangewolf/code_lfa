import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:code_lfa/config.dart';
import 'package:code_lfa/generated/l10n.dart';
import 'package:code_lfa/script.dart';
import 'package:code_lfa/utils.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:get/get.dart';
import 'package:global_repository/global_repository.dart';
import 'package:settings/settings.dart';
import 'package:xterm/xterm.dart';

/// 终端控制器，管理VS Code服务和终端交互
///
/// Terminal controller for managing VS Code service and terminal interaction
class HomeController extends GetxController {
  /// 标识VS Code是否正在启动中
  ///
  /// Flag indicating if VS Code is starting
  bool vsCodeStaring = false;

  /// 隐私设置节点
  ///
  /// Privacy settings node
  SettingNode privacySetting = 'privacy'.setting;

  /// 伪终端实例
  ///
  /// Pseudo terminal instance
  Pty? pseudoTerminal;

  /// 终端实例，管理终端交互
  ///
  /// Terminal instance for managing terminal interaction
  late Terminal terminal = Terminal(
    maxLines: 10000,
    onResize: (width, height, pixelWidth, pixelHeight) {
      pseudoTerminal?.resize(height, width);
    },
    onOutput: (data) {
      pseudoTerminal?.writeString(data);
    },
  );

  /// 标识WebView是否已打开
  ///
  /// Flag indicating if WebView is open
  bool webviewHasOpen = false;

  /// 进度记录文件
  ///
  /// File for recording progress
  File progressFile = File('${RuntimeEnvir.tmpPath}/progress');

  /// 进度描述文件
  ///
  /// File for progress description
  File progressDesFile = File('${RuntimeEnvir.tmpPath}/progress_des');

  /// 当前进度值(0-1)
  ///
  /// Current progress value (0-1)
  double progress = 0;

  /// 进度步长
  ///
  /// Progress step size
  double step = 17;

  /// 当前进度描述文本
  ///
  /// Current progress description text
  String currentProgress = '';

  /// 进度 +1
  ///
  /// Progress +1
  void bumpProgress() {
    try {
      var current = 0;
      if (progressFile.existsSync()) {
        final content = progressFile.readAsStringSync().trim();
        if (content.isNotEmpty) {
          current = int.tryParse(content) ?? 0;
        }
      } else {
        progressFile.createSync(recursive: true);
      }
      progressFile.writeAsStringSync('${current + 1}');
    } on FileSystemException {
      progressFile.writeAsStringSync('1');
    }
    update();
  }

  /// 监听输出，当输出中包含启动成功的标志时，启动 Code Server
  ///
  /// Listen for output and start the Code Server
  /// when the success flag is detected
  Future<void> vsCodeStartWhenSuccessBind() async {
    terminal.writeProgress('${S.current.listen_vscode_start}...');
    final completer = Completer<void>();
    const decoder = Utf8Decoder(allowMalformed: true);
    pseudoTerminal!.output
        .cast<List<int>>()
        .transform(decoder)
        .listen((event) async {
      if (event.contains('http://0.0.0.0:${Config.port}')) {
        Log.e(event);
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
      if (event.contains('already')) {
        Log.e(event);
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
      terminal.write(event);
    });
    await completer.future;
    bumpProgress();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    webviewHasOpen = true;
    await openWebView();
    Future.delayed(const Duration(milliseconds: 2000), () {
      vsCodeStaring = false;
      update();
    });
  }

  /// 初始化环境，将动态库中的文件链接到数据目录
  ///
  /// Init environment and link files from the dynamic library
  /// to the data directory
  Future<void> initEnvir() async {
    final androidFiles = <String>[
      'libbash.so',
      'libbusybox.so',
      'liblibtalloc.so.2.so',
      'libloader.so',
      'libproot.so',
      'libsudo.so',
    ];
    final libPath = await getLibPath();
    Log.i('libPath -> $libPath');

    for (var i = 0; i < androidFiles.length; i++) {
      // 当android目标SDK > 28
      // 无法在/data/data/com.xxx/files/usr/bin中执行文件
      // 所以我们需要创建一个链接到/data/data/com.xxx/files/usr/bin
      // when android target sdk > 28
      // cannot execute file in /data/data/com.xxx/files/usr/bin
      // so we need create a link to /data/data/com.xxx/files/usr/bin
      final sourcePath = '$libPath/${androidFiles[i]}';
      final fileName = androidFiles[i].replaceAll(RegExp(r'^lib|\.so$'), '');
      final filePath = '${RuntimeEnvir.binPath}/$fileName';
      // 自定义路径，termux-api将调用
      // custom path, termux-api will invoke
      final file = File(filePath);
      final type = FileSystemEntity.typeSync(filePath);
      Log.i('$fileName type -> $type');
      if (type != FileSystemEntityType.notFound &&
          type != FileSystemEntityType.link) {
        // 旧版本的adb是普通文件
        // old version adb is plain file
        Log.i('find plain file -> $fileName, delete it');
        await file.delete();
      }
      final link = Link(filePath);
      if (link.existsSync()) {
        link.deleteSync();
      }
      try {
        Log.i('create link -> $fileName ${link.path}');
        link.createSync(sourcePath);
      } on FileSystemException catch (e) {
        Log.e('installAdbToEnvir error -> $e');
      }
    }
  }

  /// 同步当前进度
  ///
  /// Sync the current progress
  void syncProgress() {
    progressFile
      ..createSync(recursive: true)
      ..writeAsStringSync('0');
    progressFile.watch().listen((event) async {
      if (event.type == FileSystemEvent.modify) {
        final content = await progressFile.readAsString();
        Log.e('content -> $content');
        if (content.isEmpty) {
          return;
        }
        progress = int.parse(content) / step;
        Log.e('progress -> $progress');
        update();
      }
    });
    progressDesFile
      ..createSync(recursive: true)
      ..writeAsStringSync('');
    progressDesFile.watch().listen((event) async {
      if (event.type == FileSystemEvent.modify) {
        final content = await progressDesFile.readAsString();
        currentProgress = content;
        update();
      }
    });
  }

  /// 创建 busybox 的软连接，确保 proot-distro 命令可用
  ///
  /// Create busybox symlinks to ensure proot-distro commands work
  void createBusyboxLink() {
    try {
      final links = <String>[
        ...[
          'awk',
          'ash',
          'basename',
          'bzip2',
          'curl',
          'cp',
          'chmod',
          'cut',
          'cat',
          'du',
          'dd',
          'find',
          'grep',
          'gzip',
        ],
        ...[
          'hexdump',
          'head',
          'id',
          'lscpu',
          'mkdir',
          'realpath',
          'rm',
          'sed',
          'stat',
          'sh',
          'tr',
          'tar',
          'uname',
          'xargs',
          'xz',
          'xxd',
        ],
      ];

      for (final linkName in links) {
        final link = Link('${RuntimeEnvir.binPath}/$linkName');
        if (!link.existsSync()) {
          link.createSync('${RuntimeEnvir.binPath}/busybox');
        }
      }
      Link('${RuntimeEnvir.binPath}/file').createSync('/system/bin/file');
    } on FileSystemException catch (e) {
      Log.e('Create link failed -> $e');
    }
  }

  /// 加载Code Server版本信息
  ///
  /// Load Code Server version information
  Future<void> loadCodeVersion() async {
    if (GetPlatform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      Log.i('status -> $status');
      if (!status.isGranted) {
        return;
      }
    }
    final file = File('/sdcard/code_version');
    try {
      if (!file.existsSync()) {
        file
          ..createSync()
          ..writeAsStringSync(Config.defaultCodeServerVersion);
      }
    } on FileSystemException catch (e) {
      Log.e('Create code_version file failed -> $e');
    }
    if (file.existsSync()) Config.codeServerVersion = file.readAsStringSync();
    if (Config.codeServerVersion.isEmpty) {
      Config.codeServerVersion = Config.defaultCodeServerVersion;
    }
  }

  /// 判断是否使用自定义Code Server
  ///
  /// Check if using custom Code Server
  bool get useCustomCodeServer =>
      Config.codeServerVersion != Config.defaultCodeServerVersion;

  /// 设置当前进度描述文本
  ///
  /// Set current progress description text
  void setProgress(String description) {
    currentProgress = description;
    terminal.writeProgress(currentProgress);
  }

  /// 加载并启动Code Server
  ///
  /// Load and start Code Server
  Future<void> loadCodeServer() async {
    await loadCodeVersion();
    bumpProgress();
    // 创建相关文件夹
    // Create related folders
    Directory(RuntimeEnvir.tmpPath).createSync(recursive: true);
    Directory(RuntimeEnvir.homePath).createSync(recursive: true);
    Directory(RuntimeEnvir.binPath).createSync(recursive: true);
    bumpProgress();
    await initEnvir();
    bumpProgress();
    // -
    setProgress('${S.current.create_terminal_obj}...');
    pseudoTerminal = createPTY(
      rows: terminal.viewHeight,
      columns: terminal.viewWidth,
    );
    bumpProgress();
    // -
    terminal.writeProgress(
      '''
      ${S.current.current_code_version} :
      ${Config.codeServerVersion} [${useCustomCodeServer ? 'custom' : ''}]
      ''',
    );
    setProgress('${S.current.copy_proot_distro}...');
    await AssetsUtils.copyAssetToPath(
      'assets/proot-distro.zip',
      '${RuntimeEnvir.homePath}/proot-distro.zip',
    );
    bumpProgress();
    // -
    setProgress('${S.current.copy_ubuntu}...');
    await AssetsUtils.copyAssetToPath(
      'assets/${Config.ubuntuFileName}',
      '${RuntimeEnvir.homePath}/${Config.ubuntuFileName}',
    );
    bumpProgress();
    // -
    setProgress('${S.current.create_busybox_symlink}...');
    createBusyboxLink();
    bumpProgress();
    // -
    final codeServerName =
        'code-server-${Config.codeServerVersion}-linux-arm64.tar.gz';
    final sourcePath = useCustomCodeServer
        ? '/sdcard/$codeServerName'
        : 'assets/$codeServerName';
    setProgress(
      '''
      ${S.current.copy_code_server('[$sourcePath]')} 
      ${RuntimeEnvir.tmpPath}...
      ''',
    );
    try {
      if (useCustomCodeServer) {
        final codeServerOnSdcard = File(sourcePath);
        final targetFile = File('${RuntimeEnvir.tmpPath}/$codeServerName');
        if (targetFile.lengthSync() == codeServerOnSdcard.lengthSync()) {
          Log.i('code server already copied, skip');
        }
        await codeServerOnSdcard.copy(targetFile.path);
      } else {
        await AssetsUtils.copyAssetToPath(
          sourcePath,
          '${RuntimeEnvir.tmpPath}/$codeServerName',
        );
      }
    } on FileSystemException catch (e) {
      Log.e('Copy code server failed -> $e');
      terminal.write('Copy code server failed -> $e');
      return;
    }
    // -
    final codeServerPath = '${RuntimeEnvir.tmpPath}/$codeServerName';
    setProgress('${S.current.gen_script}...');
    var fixHardLinkShell = '';
    try {
      final hardLinks = await getHardLinkMap(codeServerPath);
      fixHardLinkShell = genFixCodeServerHardLinkShell(hardLinks);
      Log.i('fixHardLinkShell -> $fixHardLinkShell');
    } on FileSystemException catch (e) {
      terminal.write(
        'Get hard link failed, will cause code-server start failed -> $e\r\n',
      );
      return;
    }
    bumpProgress();
    bumpProgress();
    // -
    await vsCodeStartWhenSuccessBind();
    bumpProgress();
    File('${RuntimeEnvir.homePath}/common.sh')
        .writeAsStringSync('$commonScript\n$fixHardLinkShell');
    bumpProgress();
    await startVsCode(pseudoTerminal!);
  }

  /// 启动VS Code服务
  ///
  /// Start VS Code service
  Future<void> startVsCode(Pty pseudoTerminal) async {
    vsCodeStaring = true;
    update();
    pseudoTerminal.writeString(
      'source ${RuntimeEnvir.homePath}/common.sh\nstart_vs_code\n',
    );
    // pseudoTerminal.writeString('bash\n');
  }

  @override
  void onInit() {
    super.onInit();
    // 为 Google Play 上架做准备
    // For Google Play
    Future.delayed(Duration.zero, () async {
      if (privacySetting.get() == null) {
        await Get.to<PrivacyAgreePage>(
          PrivacyAgreePage(
            onAgreeTap: () {
              privacySetting.set(true);
              Get.back<dynamic>();
            },
          ),
        );
      }
      syncProgress();
      await loadCodeServer();
    });
  }
}
