import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class EditorStyles {
  static DefaultStyles getInstance(BuildContext context) {
    final themeData = Theme.of(context);
    final defaultTextStyle = DefaultTextStyle.of(context);
    final baseStyle = defaultTextStyle.style.copyWith(
      fontSize: 16,
      height: 1.15,
      decoration: TextDecoration.none,
    );
    const baseHorizontalSpacing = HorizontalSpacing(0, 0);
    const baseVerticalSpacing = VerticalSpacing(6, 0);
    final fontFamily = 'CoFoGothic';

    final inlineCodeStyle = TextStyle(
      fontSize: 14,
      color: themeData.colorScheme.primary.withValues(alpha: 0.8),
      fontFamily: fontFamily,
    );

    return DefaultStyles(
      h1: DefaultTextBlockStyle(
          defaultTextStyle.style.copyWith(
            fontSize: 34,
            color: Colors.black,
            letterSpacing: -0.5,
            height: 1.083,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
            fontFamily: fontFamily,
          ),
          baseHorizontalSpacing,
          const VerticalSpacing(16, 0),
          VerticalSpacing.zero,
          null),
      h2: DefaultTextBlockStyle(
          defaultTextStyle.style.copyWith(
            fontSize: 30,
            color: Colors.black,
            letterSpacing: -0.8,
            height: 1.067,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
            fontFamily: fontFamily,
          ),
          baseHorizontalSpacing,
          const VerticalSpacing(8, 0),
          VerticalSpacing.zero,
          null),
      h3: DefaultTextBlockStyle(
        defaultTextStyle.style.copyWith(
          fontSize: 24,
          color: Colors.black,
          letterSpacing: -0.5,
          height: 1.083,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
          fontFamily: fontFamily,
        ),
        baseHorizontalSpacing,
        const VerticalSpacing(8, 0),
        VerticalSpacing.zero,
        null,
      ),
      h4: DefaultTextBlockStyle(
        defaultTextStyle.style.copyWith(
          fontSize: 20,
          color: Colors.black,
          letterSpacing: -0.4,
          height: 1.1,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
          fontFamily: fontFamily,
        ),
        baseHorizontalSpacing,
        const VerticalSpacing(6, 0),
        VerticalSpacing.zero,
        null,
      ),
      h5: DefaultTextBlockStyle(
        defaultTextStyle.style.copyWith(
          fontSize: 18,
          color: Colors.black,
          letterSpacing: -0.2,
          height: 1.11,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
          fontFamily: fontFamily,
        ),
        baseHorizontalSpacing,
        const VerticalSpacing(6, 0),
        VerticalSpacing.zero,
        null,
      ),
      h6: DefaultTextBlockStyle(
        defaultTextStyle.style.copyWith(
          fontSize: 16,
          color: Colors.black,
          letterSpacing: -0.1,
          height: 1.125,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
          fontFamily: fontFamily,
        ),
        baseHorizontalSpacing,
        const VerticalSpacing(4, 0),
        VerticalSpacing.zero,
        null,
      ),
      lineHeightNormal: DefaultTextBlockStyle(
        baseStyle.copyWith(
          height: 1.15,
          color: Colors.black,
          fontFamily: fontFamily,
        ),
        baseHorizontalSpacing,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      lineHeightTight: DefaultTextBlockStyle(
        baseStyle.copyWith(
          height: 1.30,
          color: Colors.black,
          fontFamily: fontFamily,
        ),
        baseHorizontalSpacing,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      lineHeightOneAndHalf: DefaultTextBlockStyle(
        baseStyle.copyWith(
          height: 1.55,
          color: Colors.black,
          fontFamily: fontFamily,
        ),
        baseHorizontalSpacing,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      lineHeightDouble: DefaultTextBlockStyle(
        baseStyle.copyWith(
          height: 2,
          color: Colors.black,
          fontFamily: fontFamily,
        ),
        baseHorizontalSpacing,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      paragraph: DefaultTextBlockStyle(
        baseStyle.copyWith(
          color: Colors.black,
          fontFamily: fontFamily,
        ),
        baseHorizontalSpacing,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      bold: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontFamily: fontFamily,
      ),
      subscript: TextStyle(
        color: Colors.black,
        fontFeatures: [
          FontFeature.liningFigures(),
          FontFeature.subscripts(),
        ],
        fontFamily: fontFamily,
      ),
      superscript: TextStyle(
        color: Colors.black,
        fontFeatures: [
          FontFeature.liningFigures(),
          FontFeature.superscripts(),
        ],
        fontFamily: fontFamily,
      ),
      italic: TextStyle(
        fontStyle: FontStyle.italic,
        color: Colors.black,
        fontFamily: fontFamily,
      ),
      small: TextStyle(
        fontSize: 12,
        color: Colors.black,
        fontFamily: fontFamily,
      ),
      underline: TextStyle(
        decoration: TextDecoration.underline,
        color: Colors.black,
        fontFamily: fontFamily,
      ),
      strikeThrough: TextStyle(
        decoration: TextDecoration.lineThrough,
        color: Colors.black,
        fontFamily: fontFamily,
      ),
      inlineCode: InlineCodeStyle(
        backgroundColor: Colors.black,
        radius: const Radius.circular(3),
        style: inlineCodeStyle,
        header1: inlineCodeStyle.copyWith(
            fontSize: 32, fontWeight: FontWeight.w500, color: Colors.black),
        header2: inlineCodeStyle.copyWith(
            fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black),
        header3: inlineCodeStyle.copyWith(
            fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
      ),
      link: TextStyle(
        color: Colors.blueAccent.shade700,
        decoration: TextDecoration.underline,
        decorationColor: Colors.blueAccent.shade700,
        fontFamily: fontFamily,
      ),
      placeHolder: DefaultTextBlockStyle(
          TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
            fontFamily: fontFamily,
          ),
          baseHorizontalSpacing,
          VerticalSpacing.zero,
          VerticalSpacing.zero,
          null),
      lists: DefaultListBlockStyle(
        baseStyle.copyWith(
          color: Colors.black,
          fontFamily: fontFamily,
        ),
        baseHorizontalSpacing,
        baseVerticalSpacing,
        const VerticalSpacing(0, 6),
        null,
        null,
      ),
      quote: DefaultTextBlockStyle(
        TextStyle(
          color: Colors.black,
          fontFamily: fontFamily,
        ),
        baseHorizontalSpacing,
        baseVerticalSpacing,
        const VerticalSpacing(6, 2),
        BoxDecoration(
          border: Border(
            left: BorderSide(width: 4, color: Colors.grey.shade300),
          ),
        ),
      ),
      code: DefaultTextBlockStyle(
          TextStyle(
            color: Colors.blue.shade900.withValues(alpha: 0.9),
            fontFamily: fontFamily,
            fontSize: 13,
            height: 1.15,
          ),
          baseHorizontalSpacing,
          baseVerticalSpacing,
          VerticalSpacing.zero,
          BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(2),
          )),
      indent: DefaultTextBlockStyle(
        baseStyle.copyWith(
          color: Colors.black,
          fontFamily: fontFamily,
        ),
        baseHorizontalSpacing,
        baseVerticalSpacing,
        const VerticalSpacing(0, 6),
        null,
      ),
      align: DefaultTextBlockStyle(
        baseStyle.copyWith(
          color: Colors.black,
          fontFamily: fontFamily,
        ),
        baseHorizontalSpacing,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      leading: DefaultTextBlockStyle(
        baseStyle.copyWith(
          color: Colors.black,
          fontFamily: fontFamily,
        ),
        baseHorizontalSpacing,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      sizeSmall: TextStyle(
        fontSize: 10,
        color: Colors.black,
        fontFamily: fontFamily,
      ),
      sizeLarge: TextStyle(
        fontSize: 18,
        color: Colors.black,
        fontFamily: fontFamily,
      ),
      sizeHuge: TextStyle(
        fontSize: 22,
        color: Colors.black,
        fontFamily: fontFamily,
      ),
    );
  }
}
