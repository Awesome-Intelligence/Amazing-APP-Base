// 主题色板 —— 5 套风格各自的颜色槽位。
// 已有取值别改（下游主题会跟着变）；新增风格在这里加一套。
// ignore_for_file: constant_identifier_names

import 'dart:ui' show Color;

import 'extended_colors.dart';

/// Mono 风格的一套颜色槽位。
abstract final class Mono {
  static const Color primaryLight = Color(0xFF1D1915);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color primaryContainerLight = Color(0xFFF0ECE9);
  static const Color onPrimaryContainerLight = Color(0xFF14100C);
  static const Color secondaryLight = Color(0xFF49433D);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color secondaryContainerLight = Color(0xFFE0DBD7);
  static const Color onSecondaryContainerLight = Color(0xFF25201B);
  static const Color tertiaryLight = Color(0xFF635D56);
  static const Color onTertiaryLight = Color(0xFFFFFFFF);
  static const Color tertiaryContainerLight = Color(0xFFDAD5D0);
  static const Color onTertiaryContainerLight = Color(0xFF2A2520);
  static const Color errorLight = Color(0xFFBA1A1A);
  static const Color onErrorLight = Color(0xFFFFFFFF);
  static const Color errorContainerLight = Color(0xFFFFDAD6);
  static const Color onErrorContainerLight = Color(0xFF93000A);
  static const Color backgroundLight = Color(0xFFFDFAF6);
  static const Color onBackgroundLight = Color(0xFF1D1915);
  static const Color surfaceLight = Color(0xFFFDFAF6);
  static const Color onSurfaceLight = Color(0xFF1D1915);
  static const Color surfaceVariantLight = Color(0xFFE9E5E1);
  static const Color onSurfaceVariantLight = Color(0xFF4C463F);
  static const Color outlineLight = Color(0xFF7C756E);
  static const Color outlineVariantLight = Color(0xFFDED9D5);
  static const Color scrimLight = Color(0xFF000000);
  static const Color inverseSurfaceLight = Color(0xFF322D28);
  static const Color inverseOnSurfaceLight = Color(0xFFF5F1EE);
  static const Color inversePrimaryLight = Color(0xFFE3DFDB);
  static const Color surfaceDimLight = Color(0xFFDFDAD6);
  static const Color surfaceBrightLight = Color(0xFFFDFAF6);
  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowLight = Color(0xFFF7F3F0);
  static const Color surfaceContainerLight = Color(0xFFF1EDEA);
  static const Color surfaceContainerHighLight = Color(0xFFEBE7E3);
  static const Color surfaceContainerHighestLight = Color(0xFFE5E1DD);
  static const Color primaryDark = Color(0xFFE6E2DE);
  static const Color onPrimaryDark = Color(0xFF1D1915);
  static const Color primaryContainerDark = Color(0xFF37322C);
  static const Color onPrimaryContainerDark = Color(0xFFE9E5E1);
  static const Color secondaryDark = Color(0xFFC2BCB6);
  static const Color onSecondaryDark = Color(0xFF26211C);
  static const Color secondaryContainerDark = Color(0xFF37322C);
  static const Color onSecondaryContainerDark = Color(0xFFE2DDD9);
  static const Color tertiaryDark = Color(0xFFA59F98);
  static const Color onTertiaryDark = Color(0xFF201C18);
  static const Color tertiaryContainerDark = Color(0xFF433D37);
  static const Color onTertiaryContainerDark = Color(0xFFD8D3CE);
  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color onErrorDark = Color(0xFF690005);
  static const Color errorContainerDark = Color(0xFF93000A);
  static const Color onErrorContainerDark = Color(0xFFFFDAD6);
  static const Color backgroundDark = Color(0xFF15110D);
  static const Color onBackgroundDark = Color(0xFFE7E3DF);
  static const Color surfaceDark = Color(0xFF15110D);
  static const Color onSurfaceDark = Color(0xFFE7E3DF);
  static const Color surfaceVariantDark = Color(0xFF2F2A25);
  static const Color onSurfaceVariantDark = Color(0xFFC8C3BE);
  static const Color outlineDark = Color(0xFF918B84);
  static const Color outlineVariantDark = Color(0xFF322D28);
  static const Color scrimDark = Color(0xFF000000);
  static const Color inverseSurfaceDark = Color(0xFFE7E3DF);
  static const Color inverseOnSurfaceDark = Color(0xFF322D28);
  static const Color inversePrimaryDark = Color(0xFF1D1915);
  static const Color surfaceDimDark = Color(0xFF15110D);
  static const Color surfaceBrightDark = Color(0xFF3D3731);
  static const Color surfaceContainerLowestDark = Color(0xFF100C09);
  static const Color surfaceContainerLowDark = Color(0xFF1D1915);
  static const Color surfaceContainerDark = Color(0xFF221D19);
  static const Color surfaceContainerHighDark = Color(0xFF2D2823);
  static const Color surfaceContainerHighestDark = Color(0xFF38332D);
}

/// Swiss 风格的一套颜色槽位。
abstract final class Swiss {
  static const Color redInk = Color(0xFFC40000);
  static const Color redOnDark = Color(0xFFFF3B30);
  static const Color redBlock = Color(0xFFFF0000);
  static const Color primaryLight = Color(0xFF000000);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color primaryContainerLight = Color(0xFF000000);
  static const Color onPrimaryContainerLight = Color(0xFFFFFFFF);
  static const Color secondaryLight = Color(0xFF0057B8);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color secondaryContainerLight = Color(0xFFE3ECFA);
  static const Color onSecondaryContainerLight = Color(0xFF003061);
  static const Color tertiaryLight = Color(0xFFFFCC00);
  static const Color onTertiaryLight = Color(0xFF000000);
  static const Color tertiaryContainerLight = Color(0xFFFFCC00);
  static const Color onTertiaryContainerLight = Color(0xFF000000);
  static const Color errorLight = Color(0xFFC40000);
  static const Color onErrorLight = Color(0xFFFFFFFF);
  static const Color errorContainerLight = Color(0xFFFFE5E5);
  static const Color onErrorContainerLight = Color(0xFF5C0000);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color onBackgroundLight = Color(0xFF000000);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF000000);
  static const Color surfaceVariantLight = Color(0xFFF0F0F0);
  static const Color onSurfaceVariantLight = Color(0xFF4A4A4A);
  static const Color outlineLight = Color(0xFF000000);
  static const Color outlineVariantLight = Color(0xFFD4D4D4);
  static const Color scrimLight = Color(0xFF000000);
  static const Color inverseSurfaceLight = Color(0xFF000000);
  static const Color inverseOnSurfaceLight = Color(0xFFFFFFFF);
  static const Color inversePrimaryLight = Color(0xFFFFFFFF);
  static const Color surfaceTintLight = Color(0xFFFFFFFF);
  static const Color surfaceDimLight = Color(0xFFD9D9D9);
  static const Color surfaceBrightLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowLight = Color(0xFFFAFAFA);
  static const Color surfaceContainerLight = Color(0xFFF5F5F5);
  static const Color surfaceContainerHighLight = Color(0xFFF0F0F0);
  static const Color surfaceContainerHighestLight = Color(0xFFE6E6E6);
  static const Color primaryDark = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFF000000);
  static const Color primaryContainerDark = Color(0xFFFFFFFF);
  static const Color onPrimaryContainerDark = Color(0xFF000000);
  static const Color secondaryDark = Color(0xFF5B9BE0);
  static const Color onSecondaryDark = Color(0xFF000000);
  static const Color secondaryContainerDark = Color(0xFF12304F);
  static const Color onSecondaryContainerDark = Color(0xFFCFE2FF);
  static const Color tertiaryDark = Color(0xFFFFCC00);
  static const Color onTertiaryDark = Color(0xFF000000);
  static const Color tertiaryContainerDark = Color(0xFF4A3B00);
  static const Color onTertiaryContainerDark = Color(0xFFFFE680);
  static const Color errorDark = Color(0xFFFF6B6B);
  static const Color onErrorDark = Color(0xFF3A0000);
  static const Color errorContainerDark = Color(0xFF5C0000);
  static const Color onErrorContainerDark = Color(0xFFFFD9D9);
  static const Color backgroundDark = Color(0xFF000000);
  static const Color onBackgroundDark = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF000000);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color surfaceVariantDark = Color(0xFF1A1A1A);
  static const Color onSurfaceVariantDark = Color(0xFFBFBFBF);
  static const Color outlineDark = Color(0xFFFFFFFF);
  static const Color outlineVariantDark = Color(0xFF3D3D3D);
  static const Color scrimDark = Color(0xFF000000);
  static const Color inverseSurfaceDark = Color(0xFFFFFFFF);
  static const Color inverseOnSurfaceDark = Color(0xFF000000);
  static const Color inversePrimaryDark = Color(0xFF000000);
  static const Color surfaceTintDark = Color(0xFF000000);
  static const Color surfaceDimDark = Color(0xFF000000);
  static const Color surfaceBrightDark = Color(0xFF1F1F1F);
  static const Color surfaceContainerLowestDark = Color(0xFF000000);
  static const Color surfaceContainerLowDark = Color(0xFF0D0D0D);
  static const Color surfaceContainerDark = Color(0xFF141414);
  static const Color surfaceContainerHighDark = Color(0xFF1F1F1F);
  static const Color surfaceContainerHighestDark = Color(0xFF2A2A2A);
}

/// Notion 风格的一套颜色槽位。
abstract final class Notion {
  static const Color primaryLight = Color(0xFF37352F);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color primaryContainerLight = Color(0xFFEFEDEA);
  static const Color onPrimaryContainerLight = Color(0xFF37352F);
  static const Color secondaryLight = Color(0xFF6B6A67);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color secondaryContainerLight = Color(0xFFF1F0EC);
  static const Color onSecondaryContainerLight = Color(0xFF37352F);
  static const Color tertiaryLight = Color(0xFF2EAADC);
  static const Color onTertiaryLight = Color(0xFF0D2530);
  static const Color tertiaryContainerLight = Color(0xFFDBEEF8);
  static const Color onTertiaryContainerLight = Color(0xFF10485F);
  static const Color errorLight = Color(0xFFEB5757);
  static const Color onErrorLight = Color(0xFF2B0A0A);
  static const Color errorContainerLight = Color(0xFFFBE4E4);
  static const Color onErrorContainerLight = Color(0xFF6B1D1D);
  static const Color backgroundLight = Color(0xFFF7F6F3);
  static const Color onBackgroundLight = Color(0xFF37352F);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF37352F);
  static const Color surfaceVariantLight = Color(0xFFEFEDEA);
  static const Color onSurfaceVariantLight = Color(0xFF6B6A67);
  static const Color outlineLight = Color(0xFF9B9A97);
  static const Color outlineVariantLight = Color(0xFFE9E7E4);
  static const Color scrimLight = Color(0xFF000000);
  static const Color inverseSurfaceLight = Color(0xFF37352F);
  static const Color inverseOnSurfaceLight = Color(0xFFFFFFFF);
  static const Color inversePrimaryLight = Color(0xFFFFFFFF);
  static const Color surfaceTintLight = Color(0xFFE9E7E4);
  static const Color surfaceDimLight = Color(0xFFE6E4E0);
  static const Color surfaceBrightLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowLight = Color(0xFFFBFAF8);
  static const Color surfaceContainerLight = Color(0xFFF7F6F3);
  static const Color surfaceContainerHighLight = Color(0xFFEFEDEA);
  static const Color surfaceContainerHighestLight = Color(0xFFE3E1DB);
  static const Color errorDark = Color(0xFFEB5757);
  static const Color onErrorDark = Color(0xFF2B0A0A);
  static const Color errorContainerDark = Color(0xFF4A1F1F);
  static const Color onErrorContainerDark = Color(0xFFFFD9D9);
  static const Color primaryDark = Color(0xFFE9E7E4);
  static const Color onPrimaryDark = Color(0xFF191918);
  static const Color primaryContainerDark = Color(0xFF3A3936);
  static const Color onPrimaryContainerDark = Color(0xFFF0EFEC);
  static const Color secondaryDark = Color(0xFFA8A6A3);
  static const Color onSecondaryDark = Color(0xFF191918);
  static const Color secondaryContainerDark = Color(0xFF333230);
  static const Color onSecondaryContainerDark = Color(0xFFE9E7E4);
  static const Color tertiaryDark = Color(0xFF2EAADC);
  static const Color onTertiaryDark = Color(0xFF0D2530);
  static const Color tertiaryContainerDark = Color(0xFF163C4E);
  static const Color onTertiaryContainerDark = Color(0xFFA8DCF5);
  static const Color backgroundDark = Color(0xFF191918);
  static const Color onBackgroundDark = Color(0xFFE9E7E4);
  static const Color surfaceDark = Color(0xFF202020);
  static const Color onSurfaceDark = Color(0xFFE9E7E4);
  static const Color surfaceVariantDark = Color(0xFF2F2E2C);
  static const Color onSurfaceVariantDark = Color(0xFFA8A6A3);
  static const Color outlineDark = Color(0xFF7C7A77);
  static const Color outlineVariantDark = Color(0xFF3A3936);
  static const Color scrimDark = Color(0xFF000000);
  static const Color inverseSurfaceDark = Color(0xFFE9E7E4);
  static const Color inverseOnSurfaceDark = Color(0xFF191918);
  static const Color inversePrimaryDark = Color(0xFF191918);
  static const Color surfaceTintDark = Color(0xFF3A3936);
  static const Color surfaceDimDark = Color(0xFF131211);
  static const Color surfaceBrightDark = Color(0xFF2A2928);
  static const Color surfaceContainerLowestDark = Color(0xFF131211);
  static const Color surfaceContainerLowDark = Color(0xFF1F1E1D);
  static const Color surfaceContainerDark = Color(0xFF252423);
  static const Color surfaceContainerHighDark = Color(0xFF2F2E2C);
  static const Color surfaceContainerHighestDark = Color(0xFF3A3936);
}

/// E-Ink 风格的一套颜色槽位。
abstract final class EInk {
  static const Color paper = Color(0xFFF5F3EA);
  static const Color ink = Color(0xFF20211E);
  static const Color graphite = Color(0xFF555750);
  static const Color rule = Color(0xFFBAB9B0);
  static const Color panel = Color(0xFFE6E4DA);
  static const Color primaryLight = ink;
  static const Color onPrimaryLight = paper;
  static const Color primaryContainerLight = panel;
  static const Color onPrimaryContainerLight = ink;
  static const Color secondaryLight = graphite;
  static const Color onSecondaryLight = paper;
  static const Color secondaryContainerLight = panel;
  static const Color onSecondaryContainerLight = ink;
  static const Color tertiaryLight = graphite;
  static const Color onTertiaryLight = paper;
  static const Color tertiaryContainerLight = Color(0xFFEDEBE2);
  static const Color onTertiaryContainerLight = ink;
  static const Color errorLight = ink;
  static const Color onErrorLight = paper;
  static const Color errorContainerLight = panel;
  static const Color onErrorContainerLight = ink;
  static const Color backgroundLight = paper;
  static const Color onBackgroundLight = ink;
  static const Color surfaceLight = paper;
  static const Color onSurfaceLight = ink;
  static const Color surfaceVariantLight = panel;
  static const Color onSurfaceVariantLight = graphite;
  static const Color outlineLight = graphite;
  static const Color outlineVariantLight = rule;
  static const Color scrimLight = ink;
  static const Color inverseSurfaceLight = ink;
  static const Color inverseOnSurfaceLight = paper;
  static const Color inversePrimaryLight = paper;
  static const Color surfaceTintLight = paper;
  static const Color surfaceDimLight = panel;
  static const Color surfaceBrightLight = Color(0xFFFAF9F2);
  static const Color surfaceContainerLowestLight = Color(0xFFFBFAF3);
  static const Color surfaceContainerLowLight = Color(0xFFF0EEE4);
  static const Color surfaceContainerLight = Color(0xFFEAE8DE);
  static const Color surfaceContainerHighLight = panel;
  static const Color surfaceContainerHighestLight = Color(0xFFDBD9CD);
  static const Color primaryDark = paper;
  static const Color onPrimaryDark = ink;
  static const Color primaryContainerDark = Color(0xFF34332E);
  static const Color onPrimaryContainerDark = paper;
  static const Color secondaryDark = rule;
  static const Color onSecondaryDark = ink;
  static const Color secondaryContainerDark = Color(0xFF2C2B26);
  static const Color onSecondaryContainerDark = panel;
  static const Color tertiaryDark = rule;
  static const Color onTertiaryDark = ink;
  static const Color tertiaryContainerDark = Color(0xFF34332E);
  static const Color onTertiaryContainerDark = panel;
  static const Color errorDark = paper;
  static const Color onErrorDark = ink;
  static const Color errorContainerDark = Color(0xFF34332E);
  static const Color onErrorContainerDark = paper;
  static const Color backgroundDark = ink;
  static const Color onBackgroundDark = paper;
  static const Color surfaceDark = ink;
  static const Color onSurfaceDark = paper;
  static const Color surfaceVariantDark = Color(0xFF2C2B26);
  static const Color onSurfaceVariantDark = rule;
  static const Color outlineDark = rule;
  static const Color outlineVariantDark = Color(0xFF3A3833);
  static const Color scrimDark = Color(0xFF000000);
  static const Color inverseSurfaceDark = paper;
  static const Color inverseOnSurfaceDark = ink;
  static const Color inversePrimaryDark = ink;
  static const Color surfaceTintDark = ink;
  static const Color surfaceDimDark = Color(0xFF171614);
  static const Color surfaceBrightDark = Color(0xFF34332E);
  static const Color surfaceContainerLowestDark = Color(0xFF171614);
  static const Color surfaceContainerLowDark = Color(0xFF1E1D1A);
  static const Color surfaceContainerDark = Color(0xFF262522);
  static const Color surfaceContainerHighDark = Color(0xFF2F2E2A);
  static const Color surfaceContainerHighestDark = Color(0xFF3A3833);
}

/// macOS 风格的一套颜色槽位。
abstract final class MacOS {
  static const Color primaryDark = Color(0xFF0A84FF);
  static const Color onPrimaryDark = Color(0xFFFFFFFF);
  static const Color primaryContainerDark = Color(0xFF263C54);
  static const Color onPrimaryContainerDark = Color(0xFFA9D2FF);
  static const Color secondaryDark = Color(0xFFAEAEAE);
  static const Color onSecondaryDark = Color(0xFF1C1C1E);
  static const Color secondaryContainerDark = Color(0xFF3A3A3C);
  static const Color onSecondaryContainerDark = Color(0xFFE5E5EA);
  static const Color tertiaryDark = Color(0xFF30D158);
  static const Color onTertiaryDark = Color(0xFF06210F);
  static const Color tertiaryContainerDark = Color(0xFF1C3D26);
  static const Color onTertiaryContainerDark = Color(0xFFA6F0BE);
  static const Color errorDark = Color(0xFFFF453A);
  static const Color onErrorDark = Color(0xFF2B0A05);
  static const Color errorContainerDark = Color(0xFF4A1A16);
  static const Color onErrorContainerDark = Color(0xFFFFD9D4);
  static const Color backgroundDark = Color(0xFF1C1C1E);
  static const Color onBackgroundDark = Color(0xFFF2F2F7);
  static const Color surfaceDark = Color(0xFF2C2C2E);
  static const Color onSurfaceDark = Color(0xFFF2F2F7);
  static const Color surfaceVariantDark = Color(0xFF3A3A3C);
  static const Color onSurfaceVariantDark = Color(0xFFAEAEAE);
  static const Color outlineDark = Color(0x1FFFFFFF);
  static const Color outlineVariantDark = Color(0x14FFFFFF);
  static const Color scrimDark = Color(0xFF000000);
  static const Color inverseSurfaceDark = Color(0xFFF2F2F7);
  static const Color inverseOnSurfaceDark = Color(0xFF1C1C1E);
  static const Color inversePrimaryDark = Color(0xFF0A84FF);
  static const Color surfaceTintDark = Color(0xFF0A84FF);
  static const Color surfaceDimDark = Color(0xFF161618);
  static const Color surfaceBrightDark = Color(0xFF3A3A3C);
  static const Color surfaceContainerLowestDark = Color(0xFF1C1C1E);
  static const Color surfaceContainerLowDark = Color(0xFF232325);
  static const Color surfaceContainerDark = Color(0xFF2C2C2E);
  static const Color surfaceContainerHighDark = Color(0xFF333336);
  static const Color surfaceContainerHighestDark = Color(0xFF3A3A3C);
  static const Color primaryLight = Color(0xFF0060D6);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color primaryContainerLight = Color(0xFFDCEBFF);
  static const Color onPrimaryContainerLight = Color(0xFF003A73);
  static const Color secondaryLight = Color(0xFF6E6E73);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color secondaryContainerLight = Color(0xFFE9E9EE);
  static const Color onSecondaryContainerLight = Color(0xFF1C1C1E);
  static const Color tertiaryLight = Color(0xFF1E7A34);
  static const Color onTertiaryLight = Color(0xFFFFFFFF);
  static const Color tertiaryContainerLight = Color(0xFFDFF3E6);
  static const Color onTertiaryContainerLight = Color(0xFF0B3D1C);
  static const Color errorLight = Color(0xFFD70015);
  static const Color onErrorLight = Color(0xFFFFFFFF);
  static const Color errorContainerLight = Color(0xFFFFE5E3);
  static const Color onErrorContainerLight = Color(0xFF7A0B05);
  static const Color backgroundLight = Color(0xFFF2F2F7);
  static const Color onBackgroundLight = Color(0xFF1C1C1E);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF1C1C1E);
  static const Color surfaceVariantLight = Color(0xFFEDEDF0);
  static const Color onSurfaceVariantLight = Color(0xFF6E6E73);
  static const Color outlineLight = Color(0x1F000000);
  static const Color outlineVariantLight = Color(0x14000000);
  static const Color scrimLight = Color(0xFF000000);
  static const Color inverseSurfaceLight = Color(0xFF1C1C1E);
  static const Color inverseOnSurfaceLight = Color(0xFFF2F2F7);
  static const Color inversePrimaryLight = Color(0xFF007AFF);
  static const Color surfaceTintLight = Color(0xFF007AFF);
  static const Color surfaceDimLight = Color(0xFFE0E0E4);
  static const Color surfaceBrightLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowLight = Color(0xFFFAFAFC);
  static const Color surfaceContainerLight = Color(0xFFF2F2F7);
  static const Color surfaceContainerHighLight = Color(0xFFEDEDF0);
  static const Color surfaceContainerHighestLight = Color(0xFFE6E6EA);
  static const Color vibrancyDark = Color(0xCC1C1C1E);
  static const Color vibrancyLight = Color(0xCCF7F7F9);
  static const Color selectionDark = Color(0x2E0A84FF);
  static const Color selectionLight = Color(0x2E007AFF);
}

/// Swiss 浅色扩展色。
const ExtendedColors SwissLightExtended = ExtendedColors(
  success: Color(0xFF1B7A4B),
  onSuccess: Color(0xFFFFFFFF),
  successContainer: Color(0xFFDFF2E6),
  onSuccessContainer: Color(0xFF0F5132),
  warning: Color(0xFF8A5A00),
  onWarning: Color(0xFFFFFFFF),
  warningContainer: Color(0xFFFFF0D0),
  onWarningContainer: Color(0xFF5A3A00),
  aiAccent: Color(0xFF0057B8),
  aiContainer: Color(0xFFE3ECFA),
  onAiContainer: Color(0xFF003061),
  star: Color(0xFF6C3B00),
);

/// Swiss 深色扩展色。
const ExtendedColors SwissDarkExtended = ExtendedColors(
  success: Color(0xFF6BCB96),
  onSuccess: Color(0xFF003822),
  successContainer: Color(0xFF1B4D35),
  onSuccessContainer: Color(0xFF8FE3BC),
  warning: Color(0xFFE8B84B),
  onWarning: Color(0xFF3F2D00),
  warningContainer: Color(0xFF57430F),
  onWarningContainer: Color(0xFFFFD98A),
  aiAccent: Color(0xFF5B9BE0),
  aiContainer: Color(0xFF12304F),
  onAiContainer: Color(0xFFCFE2FF),
  star: Color(0xFFC08A3E),
);

/// Notion 浅色扩展色。
const ExtendedColors NotionLightExtended = ExtendedColors(
  success: Color(0xFF0F7B6C),
  onSuccess: Color(0xFFFFFFFF),
  successContainer: Color(0xFFD7EBE7),
  onSuccessContainer: Color(0xFF04443C),
  warning: Color(0xFF8A6800),
  onWarning: Color(0xFFFFFFFF),
  warningContainer: Color(0xFFF7EDD0),
  onWarningContainer: Color(0xFF5A4300),
  aiAccent: Color(0xFF6D4AD8),
  aiContainer: Color(0xFFEFE9FB),
  onAiContainer: Color(0xFF26174F),
  star: Color(0xFF8A6800),
);

/// Notion 深色扩展色。
const ExtendedColors NotionDarkExtended = ExtendedColors(
  success: Color(0xFF4FBFAE),
  onSuccess: Color(0xFF00382F),
  successContainer: Color(0xFF1C4A42),
  onSuccessContainer: Color(0xFF7FE3D3),
  warning: Color(0xFFE0B64B),
  onWarning: Color(0xFF3A2B00),
  warningContainer: Color(0xFF4A3A0C),
  onWarningContainer: Color(0xFFFFE08A),
  aiAccent: Color(0xFFB39CF0),
  aiContainer: Color(0xFF322A52),
  onAiContainer: Color(0xFFE6DCFF),
  star: Color(0xFFE0B64B),
);

/// E-Ink 浅色扩展色。
const ExtendedColors EInkLightExtended = ExtendedColors(
  success: Color(0xFF6E6D64),
  onSuccess: Color(0xFF20211E),
  successContainer: Color(0xFFE6E4DA),
  onSuccessContainer: Color(0xFF3A3A34),
  warning: Color(0xFF45463F),
  onWarning: Color(0xFFF5F3EA),
  warningContainer: Color(0xFFEDEBE2),
  onWarningContainer: Color(0xFF3A3A34),
  aiAccent: Color(0xFF20211E),
  aiContainer: Color(0xFFE6E4DA),
  onAiContainer: Color(0xFF20211E),
  star: Color(0xFF555750),
);

/// E-Ink 深色扩展色。
const ExtendedColors EInkDarkExtended = ExtendedColors(
  success: Color(0xFFA9A79C),
  onSuccess: Color(0xFF20211E),
  successContainer: Color(0xFF34332E),
  onSuccessContainer: Color(0xFFD8D6CC),
  warning: Color(0xFFE8E6DB),
  onWarning: Color(0xFF20211E),
  warningContainer: Color(0xFF45443D),
  onWarningContainer: Color(0xFFE0DED4),
  aiAccent: Color(0xFFF5F3EA),
  aiContainer: Color(0xFF34332E),
  onAiContainer: Color(0xFFF5F3EA),
  star: Color(0xFFBAB9B0),
);

/// macOS 深色扩展色。
const ExtendedColors MacOSDarkExtended = ExtendedColors(
  success: Color(0xFF30D158),
  onSuccess: Color(0xFF06210F),
  successContainer: Color(0xFF1C3D26),
  onSuccessContainer: Color(0xFF7BE89B),
  warning: Color(0xFFFF9F0A),
  onWarning: Color(0xFF2B1A00),
  warningContainer: Color(0xFF4A3208),
  onWarningContainer: Color(0xFFFFC46B),
  aiAccent: Color(0xFF0A84FF),
  aiContainer: Color(0xFF16324B),
  onAiContainer: Color(0xFFA9D2FF),
  star: Color(0xFFFFD60A),
);

/// macOS 浅色扩展色。
const ExtendedColors MacOSLightExtended = ExtendedColors(
  success: Color(0xFF1B7F3B),
  onSuccess: Color(0xFFFFFFFF),
  successContainer: Color(0xFFDFF3E6),
  onSuccessContainer: Color(0xFF0B4D22),
  warning: Color(0xFFA8620A),
  onWarning: Color(0xFFFFFFFF),
  warningContainer: Color(0xFFFFF0D6),
  onWarningContainer: Color(0xFF6B3C00),
  aiAccent: Color(0xFF007AFF),
  aiContainer: Color(0xFFDCEBFF),
  onAiContainer: Color(0xFF003A73),
  star: Color(0xFF8A6D00),
);

/// 浅色扩展色。
const ExtendedColors LightExtended = ExtendedColors(
  success: Color(0xFF2D6A4F),
  onSuccess: Color(0xFFFFFFFF),
  successContainer: Color(0xFFD8F3E4),
  onSuccessContainer: Color(0xFF0A3D24),
  warning: Color(0xFFB75D00),
  onWarning: Color(0xFFFFFFFF),
  warningContainer: Color(0xFFFFECCF),
  onWarningContainer: Color(0xFF6B3C00),
  aiAccent: Color(0xFF5E35B1),
  aiContainer: Color(0xFFEDE7F6),
  onAiContainer: Color(0xFF241436),
  star: Color(0xFFC77800),
);

/// 深色扩展色。
const ExtendedColors DarkExtended = ExtendedColors(
  success: Color(0xFF6BCB96),
  onSuccess: Color(0xFF003822),
  successContainer: Color(0xFF1B4D35),
  onSuccessContainer: Color(0xFF8FE3BC),
  warning: Color(0xFFFFB95C),
  onWarning: Color(0xFF462900),
  warningContainer: Color(0xFF6B3900),
  onWarningContainer: Color(0xFFFFD98A),
  aiAccent: Color(0xFFB39DDB),
  aiContainer: Color(0xFF3D2B6B),
  onAiContainer: Color(0xFFEDE7F6),
  star: Color(0xFFFFD54F),
);
