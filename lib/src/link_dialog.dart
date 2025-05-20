import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:html_editor/editor.dart';
import 'package:html_editor/src/html_input_field.dart';

class LinkDialog {
  static Future<void> showCustomLinkDialog(
      BuildContext context, QuillController controller) async {
    final selection = controller.selection;

    final nameController = TextEditingController();
    final linkController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Dialog(
              backgroundColor: context.editorTheme.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              child: StatefulBuilder(builder: (_, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: context.editorTheme.bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Добавить ссылку',
                              style: AppTextStyle.headlineH18Medium,
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context, false),
                              child: SvgPicture.asset(
                                HtmlIcons.close,
                                color: context.editorTheme.gray800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      HtmlInputField(
                        context: context,
                        controller: nameController,
                        customContentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        cursorColor: context.editorTheme.gray700,
                        onChanged: (_) => setState(() {}),
                        onTapOutside: (event) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        hint: 'Название',
                        hintStyle: AppTextStyle.textT14Regular.copyWith(
                          color: context.editorTheme.gray400,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(
                            color: context.editorTheme.gray800,
                          ),
                        ),
                      ),
                      HtmlInputField(
                        context: context,
                        controller: linkController,
                        customContentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        cursorColor: context.editorTheme.gray700,
                        onChanged: (_) => setState(() {}),
                        onTapOutside: (event) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        hint: 'Ссылка',
                        hintStyle: AppTextStyle.textT14Regular.copyWith(
                          color: context.editorTheme.gray400,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(
                            color: context.editorTheme.gray800,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color?>(
                                  nameController.text.isNotEmpty &&
                                          linkController.text.isNotEmpty
                                      ? context.editorTheme.gray800
                                      : context.editorTheme.gray800
                                          .withValues(alpha: 0.7)),
                              minimumSize: WidgetStateProperty.all<Size?>(
                                  const Size.fromHeight(48)),
                              shape: WidgetStateProperty.all<OutlinedBorder?>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              textStyle: WidgetStateProperty.all<TextStyle?>(
                                  AppTextStyle.headlineH14Medium.copyWith(
                                      color: context.editorTheme.gray0)),
                              elevation: WidgetStateProperty.all<double>(0),
                            ),
                            onPressed: () {
                              if (nameController.text.isNotEmpty &&
                                  linkController.text.isNotEmpty) {
                                Navigator.pop(context, true);
                              }
                            },
                            child: Text(
                              'Добавить',
                              style: AppTextStyle.headlineH14Medium
                                  .copyWith(color: context.editorTheme.gray0),
                            )),
                      )
                    ],
                  ),
                );
              }),
            ),
          ],
        );
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
