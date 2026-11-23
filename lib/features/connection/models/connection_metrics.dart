/// Метрики текущего VPN-подключения.
///
/// Содержит информацию о скорости, трафике и времени подключения.
class ConnectionMetrics {
  /// Скорость загрузки (bytes/sec)
  final int downloadSpeed;

  /// Скорость выгрузки (bytes/sec)
  final int uploadSpeed;

  /// Загружено всего (bytes)
  final int totalDownloaded;

  /// Выгружено всего (bytes)
  final int totalUploaded;

  /// Длительность подключения (секунды)
  final int connectionDuration;

  /// Задержка (ping) в миллисекундах
  final int? latency;

  const ConnectionMetrics({
    this.downloadSpeed = 0,
    this.uploadSpeed = 0,
    this.totalDownloaded = 0,
    this.totalUploaded = 0,
    this.connectionDuration = 0,
    this.latency,
  });

  /// Создать пустые метрики (для отключенного состояния)
  const ConnectionMetrics.empty()
      : downloadSpeed = 0,
        uploadSpeed = 0,
        totalDownloaded = 0,
        totalUploaded = 0,
        connectionDuration = 0,
        latency = null;

  /// Создать копию с изменёнными полями
  ConnectionMetrics copyWith({
    int? downloadSpeed,
    int? uploadSpeed,
    int? totalDownloaded,
    int? totalUploaded,
    int? connectionDuration,
    int? latency,
  }) {
    return ConnectionMetrics(
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      totalDownloaded: totalDownloaded ?? this.totalDownloaded,
      totalUploaded: totalUploaded ?? this.totalUploaded,
      connectionDuration: connectionDuration ?? this.connectionDuration,
      latency: latency ?? this.latency,
    );
  }

  /// Форматировать скорость в человекочитаемый вид (KB/s, MB/s)
  static String formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '$bytesPerSecond B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  /// Форматировать трафик в человекочитаемый вид (KB, MB, GB)
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Форматировать длительность, показывая часы при ненулевом значении
  /// или когда [alwaysShowHours] задан для таймера подключения.
  static String formatDuration(int seconds, {bool alwaysShowHours = false}) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0 || alwaysShowHours) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  String toString() {
    return 'ConnectionMetrics('
        'down: ${formatSpeed(downloadSpeed)}, '
        'up: ${formatSpeed(uploadSpeed)}, '
        'total: ${formatBytes(totalDownloaded + totalUploaded)}, '
        'duration: ${formatDuration(connectionDuration)}, '
        'latency: ${latency ?? "—"}ms'
        ')';
  }
}
