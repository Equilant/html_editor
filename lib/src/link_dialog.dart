import 'package:flutter/material.dart';
import 'package:html_editor/editor.dart';

class LinkDialog {
  static Future<void> showCustomLinkDialog(
      BuildContext context, QuillController controller) async {
    final selection = controller.selection;

    final nameController = TextEditingController();
    final linkController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (_, setState) {
          return AlertDialog(
            title: const Text('Добавить ссылку'),
            backgroundColor: context.theme.bg,
            insetPadding: const EdgeInsets.all(24),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            titleTextStyle: AppTextStyle.headlineH24Regular
                .copyWith(color: context.theme.gray800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Название',
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: context.theme.gray800, width: 1.5),
                      ),
                      labelStyle: AppTextStyle.textT14Regular
                          .copyWith(color: context.theme.gray800),
                    ),
                    style: AppTextStyle.textT14Regular
                        .copyWith(color: context.theme.gray800),
                    onChanged: (_) => setState(() {}),
                  ),
                  TextField(
                    controller: linkController,
                    decoration: InputDecoration(
                      labelText: 'Ссылка',
                      hintText: 'например, google.com',
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: context.theme.gray800, width: 1.5),
                      ),
                      labelStyle: AppTextStyle.textT14Regular
                          .copyWith(color: context.theme.gray800),
                    ),
                    style: AppTextStyle.textT14Regular
                        .copyWith(color: context.theme.gray800),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                style: ButtonStyle(
                  foregroundColor:
                      WidgetStateProperty.all(context.theme.gray800),
                ),
                child: const Text('Отмена'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all(
                      nameController.text.isNotEmpty &&
                              linkController.text.isNotEmpty
                          ? context.theme.gray800
                          : context.theme.gray400),
                ),
                child: const Text('Добавить'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          );
        });
      },
    );

    if (result == true) {
      final name = nameController.text.trim();
      var link = linkController.text.trim();

      if (name.isNotEmpty && link.isNotEmpty) {
        if (!link.startsWith('http://') && !link.startsWith('https://')) {
          link = 'https://$link';
        }

        controller.replaceText(
          selection.start,
          selection.end - selection.start,
          name,
          TextSelection.collapsed(offset: selection.start + name.length),
        );
        controller.formatText(
          selection.start,
          name.length,
          LinkAttribute(link),
        );
      }
    }
  }
}
