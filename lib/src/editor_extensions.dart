import 'package:flutter/material.dart';
import 'package:untitled100/src/theme/editor_theme.dart';

import '../editor.dart';

extension ThemeContextGetter on BuildContext {
  EditorTheme get theme => EditorTheme.of(this);
}

extension HtmlAlignmentTypeExt on HtmlAlignmentType {
  String get title => switch (this) {
        HtmlAlignmentType.left => 'слева',
        HtmlAlignmentType.right => 'справа',
        HtmlAlignmentType.center => 'по центру',
        HtmlAlignmentType.justify => 'по ширине',
      };
}
