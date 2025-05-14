import 'package:flutter/material.dart';
import 'package:html_editor/editor.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsDialog {
  static Future<void> showPermissionDialog(BuildContext context) async {
    await showAdaptiveDialog(
      context: context,
      builder: (_) {
        return AlertDialog.adaptive(
          title: Text(
            'Требуется разрешение',
            style: AppTextStyle.headlineH18Medium
                .copyWith(color: context.theme.gray800),
          ),
          content: Text(
            'Для выполнения этого действия необходимо разрешение. Пожалуйста, откройте настройки приложения и предоставьте доступ.',
            style: AppTextStyle.textT14Regular
                .copyWith(color: context.theme.gray800),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Отмена',
                style: AppTextStyle.headlineH16Medium
                    .copyWith(color: context.theme.gray800),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: Text(
                'Настройки',
                style: AppTextStyle.headlineH16Medium
                    .copyWith(color: context.theme.gray800),
              ),
            ),
          ],
        );
      },
    );
  }
}
