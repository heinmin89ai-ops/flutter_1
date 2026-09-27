import 'package:flutter/material.dart';

/// Owns the app's language choice. Kept above [MaterialApp] so the switch can
/// rebuild the whole tree, while pages below it can still read it.
class AppLocaleController extends ChangeNotifier {
  AppLocaleController(this._locale);

  Locale? _locale;

  Locale? get locale => _locale;

  bool get isBurmese => (_locale ?? const Locale('en')).languageCode == 'my';

  void toggle() {
    _locale = isBurmese ? const Locale('en') : const Locale('my');
    notifyListeners();
  }
}

class AppLocaleScope extends InheritedWidget {
  const AppLocaleScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final AppLocaleController controller;

  static AppLocaleController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLocaleScope>()!.controller;

  @override
  bool updateShouldNotify(AppLocaleScope oldWidget) => controller != oldWidget.controller;
}
