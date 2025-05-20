import 'package:flutter/material.dart';
import 'package:html_editor/src/theme/editor_colors.dart';

class EditorTheme extends InheritedWidget {
  final Brightness brightness;

  const EditorTheme({
    super.key,
    required this.brightness,
    required super.child,
  });

  bool get isDark => brightness == Brightness.dark;

  Color get bg => isDark ? EditorColors.bgDark : EditorColors.bg;

  Color get bgGrid => isDark ? EditorColors.bgGridDark : EditorColors.bgGrid;

  Color get gray800 => isDark ? EditorColors.gray800Dark : EditorColors.gray800;

  Color get gray700 => isDark ? EditorColors.gray700Dark : EditorColors.gray700;

  Color get gray500 => isDark ? EditorColors.gray500Dark : EditorColors.gray500;

  Color get gray400 => isDark ? EditorColors.gray400Dark : EditorColors.gray400;

  Color get gray100 => isDark ? EditorColors.gray100Dark : EditorColors.gray100;

  Color get gray0 => isDark ? EditorColors.gray0Dark : EditorColors.gray0;

  Color get orange800 =>
      isDark ? EditorColors.orange800Dark : EditorColors.orange800;

  Color get orange500 =>
      isDark ? EditorColors.orange500Dark : EditorColors.orange500;

  Color get orange100 =>
      isDark ? EditorColors.orange100Dark : EditorColors.orange100;

  Color get orange50 =>
      isDark ? EditorColors.orange50Dark : EditorColors.orange50;

  Color get red800 => isDark ? EditorColors.red800Dark : EditorColors.red800;

  Color get generalGray800 => EditorColors.gray800;

  Color get generalGray0 => EditorColors.gray0;

  Color get generalGray700 => EditorColors.gray700;

  Color get generalBg => EditorColors.bg;

  Color get red500 => isDark ? EditorColors.red500Dark : EditorColors.red500;

  Color get gray50 => isDark ? EditorColors.gray50Dark : EditorColors.gray50;

  static EditorTheme of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<EditorTheme>();
    assert(result != null, 'No EditorTheme found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(EditorTheme oldWidget) =>
      brightness != oldWidget.brightness;
}
