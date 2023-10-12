// coverage:ignore-file

part of '../../simple_architecture.dart';

enum AnsiColors {
  reset("\x1B[0m"),
  black("\x1B[30m"),
  red("\x1B[31m"),
  green("\x1B[32m"),
  yellow("\x1B[33m"),
  blue("\x1B[34m"),
  magenta("\x1B[35m"),
  cyan("\x1B[36m"),
  white("\x1B[37m"),
  brightBlack("\x1B[90m"),
  brightRed("\x1B[91m"),
  brightGreen("\x1B[92m"),
  brightYellow("\x1B[93m"),
  brightBlue("\x1B[94m"),
  brightMagenta("\x1B[95m"),
  brightCyan("\x1B[96m"),
  brightWhite("\x1B[97m");

  const AnsiColors(this.code);

  final String code;

  @override
  String toString() => code;
}

enum LogLevel {
  error,
  warning,
  config,
  info,
  shout,
  debug,
}

final class Logger<T> {
  Logger();

  static final logLevels = kDebugMode
      ? LogLevel.values
      : [
          LogLevel.error,
          LogLevel.warning,
          LogLevel.info,
        ];

  final _surfaceBrightness = HSLColor.fromColor(
        const Color(0xFF2a2d2e),
      ).lightness *
      3.33;

  final _titles = <String, String>{};

  void error(String message, [Object? exception, StackTrace? stackTrace]) {
    if (logLevels.contains(LogLevel.error) == false) {
      return;
    }

    _log(
      "⛔E",
      AnsiColors.red,
      exception == null ? message : "$message\n$exception",
    );

    if (kDebugMode && stackTrace != null) {
      debugPrintStack(
        stackTrace: stackTrace,
        label: exception.runtimeType.toString(),
      );
    }
  }

  void warning(String message) {
    if (logLevels.contains(LogLevel.warning) == false) {
      return;
    }

    _log("🟠W", AnsiColors.yellow, message);
  }

  void info(String message) {
    if (logLevels.contains(LogLevel.info) == false) {
      return;
    }

    _log("🔵I", AnsiColors.brightBlue, message);
  }

  void config(String message) {
    if (logLevels.contains(LogLevel.config) == false) {
      return;
    }

    _log("🟢C", AnsiColors.green, message);
  }

  void debug(String Function() messageFactory) {
    if (kDebugMode || logLevels.contains(LogLevel.debug) == false) {
      return;
    }

    _log("🟤D", AnsiColors.brightBlack, messageFactory());
  }

  void shout(String message) {
    if (logLevels.contains(LogLevel.shout) == false) {
      return;
    }

    _log("🟡S", AnsiColors.brightBlack, message);
  }

  void _log(String header, AnsiColors color, String message) {
    final logName = "$T".startsWith("_") ? "$T".substring(1) : "$T";
    final titleKey = "$logName:${header.substring(header.length - 1)}";
    var title = _titles[titleKey];

    if (title == null) {
      int hash = 0;

      for (int i = 0; i < logName.length; i++) {
        hash = logName.codeUnitAt(i) + ((hash << 5) - hash);
      }

      var titleColor = Color.fromARGB(
        255,
        hash & 0xFF,
        (hash >> 8) & 0xFF,
        (hash >> 16) & 0xFF,
      );

      final colorBrightness = titleColor.computeLuminance();

      if (colorBrightness < _surfaceBrightness) {
        final hslColor = HSLColor.fromColor(titleColor).withLightness(
          _surfaceBrightness,
        );

        titleColor = hslColor.toColor();
      }

      final o = logName.indexOf("<");

      if (o > -1) {
        final c = logName.lastIndexOf(">");
        final titleHSLColor = HSLColor.fromColor(titleColor);

        var titleSColor = titleHSLColor
            .withLightness((titleHSLColor.lightness + 0.1).clamp(0, 1))
            .withSaturation((titleHSLColor.saturation + 0.1).clamp(0, 1))
            .toColor();

        if (header.endsWith("D")) {
          final titleHSLColor = HSLColor.fromColor(titleColor);

          titleColor = titleHSLColor
              .withSaturation(titleHSLColor.saturation / 4)
              .withLightness(titleHSLColor.lightness / 1.25)
              .toColor();

          final titleSHSLColor = HSLColor.fromColor(titleSColor);

          titleSColor = titleSHSLColor
              .withSaturation(titleHSLColor.saturation / 4)
              .withLightness(titleHSLColor.lightness / 1.25)
              .toColor();
        }

        title = _titles[titleKey] = "\x1b[38;2;"
            "${titleColor.red};${titleColor.green};${titleColor.blue}m"
            "[${logName.substring(0, o)}"
            "\x1b[38;2;"
            "${titleSColor.red};${titleSColor.green};${titleSColor.blue}m"
            "${logName.substring(o, c + 1)}"
            "\x1b[38;2;"
            "${titleColor.red};${titleColor.green};${titleColor.blue}m"
            "] $color";
      } else {
        title = _titles[titleKey] = "\x1b[38;2;${titleColor.red};"
            "${titleColor.green};${titleColor.blue}m"
            "[$logName] $color";
      }
    }

    message = message.replaceAll("${AnsiColors.reset}", "$color");
    Dev.log("$title$message", name: header);
  }
}
