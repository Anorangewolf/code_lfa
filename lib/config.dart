/// 生产环境标识
///
/// 通过 Dart VM 环境变量 'dart.vm.product' 获取当前运行环境类型：
/// - `true`：表示当前运行在生产环境（使用 `--release` 标志构建）
/// - `false`：表示当前运行在开发/调试环境
const bool product = bool.fromEnvironment('dart.vm.product');

/// 开发环境默认代码服务器版本号
const String debugCSV = '4.103.1';

/// 应用程序配置类
///
/// 包含应用的全局配置参数和常量，所有成员均为静态属性。
/// 提供应用版本、包名、服务器配置等关键信息的集中管理。
///
/// 注意：这是一个工具类，不能实例化（构造函数为私有）。
class Config {
  Config._();

  /// 应用程序的包名，用于应用标识和系统集成，格式为反向域名。
  /// The package name of the app
  static const String packageName = 'com.nightmare.code';

  /// 应用版本名称
  ///
  /// 从构建环境变量 'VERSION' 获取，通常在构建时通过 `--dart-define` 参数设置。
  /// 用于显示应用版本号和版本检查。
  static const String versionName = String.fromEnvironment('VERSION');

  /// 默认的代码服务器版本
  ///
  /// 根据运行环境自动选择：
  /// - 生产环境：从环境变量 'CSVERSION' 获取
  /// - 开发环境：使用本地调试版本
  static const String defaultCodeServerVersion =
      product ? String.fromEnvironment('CSVERSION') : debugCSV;

  /// 当前使用的代码服务器版本
  static String codeServerVersion = defaultCodeServerVersion;

  /// 服务器端口号
  static int port = 20000;

  /// Ubuntu 系统镜像文件名
  ///
  /// 用于指定要使用的镜像。
  static String ubuntuFileName = 'ubuntu-noble-aarch64-pd-v4.18.0.tar.xz';
}
