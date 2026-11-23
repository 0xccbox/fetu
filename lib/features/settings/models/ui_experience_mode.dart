/// Режим работы интерфейса (AGENTS.md, правило 33).
///
/// В простом режиме сетевые термины и ошибки переводятся
/// [UxTerminologyTranslator]'ом на человеческий язык; в расширенном —
/// показывается полная телеметрия под капотом.
enum UiExperienceMode {
  /// Простой режим: человеческие названия, минимум настроек.
  simple,

  /// Расширенный режим: протоколы, Real-Delay, .srs, developer_meta.
  advanced;

  /// Разбирает режим из значения хранилища.
  ///
  /// Неизвестное или повреждённое значение трактуется как null
  /// (режим не выбран — показать экран выбора).
  static UiExperienceMode? fromStorage(String? value) => switch (value) {
        'simple' => UiExperienceMode.simple,
        'advanced' => UiExperienceMode.advanced,
        _ => null,
      };

  /// Стабильное имя для хранилища.
  String get storageName => switch (this) {
        UiExperienceMode.simple => 'simple',
        UiExperienceMode.advanced => 'advanced',
      };
}
