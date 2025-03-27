import 'package:flutter/material.dart';

class AppTextStyle {
  static late double baseSize;

  AppTextStyle(double baseSize) {
    // ignore: prefer_initializing_formals
    AppTextStyle.baseSize = baseSize;
  }

  static const fontFamily = 'CoFoGothic';

  static late DeviceType screenType;

  static String _fontFamily(CoFoGothicFontType type) {
    switch (type) {
      case CoFoGothicFontType.light:
        return '$fontFamily-Light';
      case CoFoGothicFontType.thin:
        return '$fontFamily-Thin';
      case CoFoGothicFontType.regular:
        return '$fontFamily-Regular';
      case CoFoGothicFontType.medium:
        return '$fontFamily-Medium';
      case CoFoGothicFontType.bold:
        return '$fontFamily-Bold';
      case CoFoGothicFontType.black:
        return '$fontFamily-Black';
    }
  }

  static double get fontSize24 => (baseSize * 2.4).roundToDouble();

  static double get fontSize18 => (baseSize * 1.8).roundToDouble();

  static double get fontSize16 => (baseSize * 1.6).roundToDouble();

  static double get fontSize14 => (baseSize * 1.4).roundToDouble();

  static double get fontSize12 => (baseSize * 1.2).roundToDouble();

  static double get fontSize10 => (baseSize * 1.0).roundToDouble();

  static const medium = FontWeight.w500;
  static const regular = FontWeight.w400;

  static TextStyle headlineH24Medium = TextStyle(
    fontFamily: _fontFamily(CoFoGothicFontType.medium),
    fontWeight: medium,
    fontSize: fontSize24,
  );

  static TextStyle headlineH18Medium = TextStyle(
    fontFamily: _fontFamily(CoFoGothicFontType.medium),
    fontWeight: medium,
    fontSize: fontSize18,
  );

  static TextStyle headlineH18Regular = TextStyle(
    fontFamily: _fontFamily(CoFoGothicFontType.regular),
    fontWeight: regular,
    fontSize: fontSize18,
  );

  static TextStyle headlineH16Medium = TextStyle(
    fontFamily: _fontFamily(CoFoGothicFontType.medium),
    fontWeight: medium,
    fontSize: fontSize16,
  );

  static TextStyle headlineH16Regular = TextStyle(
    fontFamily: _fontFamily(CoFoGothicFontType.regular),
    fontWeight: regular,
    fontSize: fontSize16,
  );

  static TextStyle headlineH14Medium = TextStyle(
    fontFamily: _fontFamily(CoFoGothicFontType.medium),
    fontWeight: medium,
    fontSize: fontSize14,
  );

  static TextStyle textT14Regular = TextStyle(
    fontFamily: _fontFamily(CoFoGothicFontType.regular),
    fontWeight: regular,
    fontSize: fontSize14,
  );

  static TextStyle textT12Medium = TextStyle(
    fontFamily: _fontFamily(CoFoGothicFontType.medium),
    fontWeight: medium,
    fontSize: fontSize12,
  );

  static TextStyle textT12Regular = TextStyle(
    fontFamily: _fontFamily(CoFoGothicFontType.regular),
    fontWeight: regular,
    fontSize: fontSize12,
  );

  static TextStyle textT10Medium = TextStyle(
    fontFamily: _fontFamily(CoFoGothicFontType.medium),
    fontWeight: medium,
    fontSize: fontSize10,
  );

  static TextStyle textT10Regular = TextStyle(
    fontFamily: _fontFamily(CoFoGothicFontType.regular),
    fontWeight: regular,
    fontSize: fontSize10,
  );

  static void init({
    double? screenWidth,
    double? pixelRatio,
  }) {
    if (pixelRatio == null || screenWidth == null) {
      screenType = DeviceType.medium;
    } else {
      final logicalWidth = screenWidth / pixelRatio;
      if (logicalWidth < 375) {
        screenType = DeviceType.small;
      } else if (logicalWidth >= 375 && logicalWidth < 414) {
        screenType = DeviceType.medium;
      } else {
        screenType = DeviceType.big;
      }
    }

    switch (screenType) {
      case DeviceType.small:
        baseSize = SMALL_BASE_SIZE;
        break;
      case DeviceType.medium:
        baseSize = MEDIUM_BASE_SIZE;
        break;
      case DeviceType.big:
        baseSize = BIG_BASE_SIZE;
        break;
    }
    AppTextStyle(baseSize);
  }
}

enum CoFoGothicFontType { light, thin, regular, medium, bold, black }

enum DeviceType { small, medium, big }

const SMALL_BASE_SIZE = 9.0;
const MEDIUM_BASE_SIZE = 10.0;
const BIG_BASE_SIZE = 11.0;
