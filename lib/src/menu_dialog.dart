import 'package:flutter/material.dart';
import 'package:untitled100/html_editor.dart';
import 'package:untitled100/src/html_editor_controller.dart';

class MenuDialog {
  static Future<void> showAlignmentMenu(
      BuildContext context,
      IHtmlEditorController controller,
      EditorColors? editorColors,
      GlobalKey iconKey, // Добавляем ключ иконки
      ) async {
    final RenderBox overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;

    final RenderBox renderBox =
    iconKey.currentContext?.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final Size size = renderBox.size;

    showMenu(
      context: context,
      color: editorColors?.backgroundColor,
      position: RelativeRect.fromLTRB(
        offset.dx, // Позиция X иконки
        offset.dy + size.height, // Позиция Y + высота иконки
        offset.dx + size.width, // Для позиционирования относительно правой границы
        offset.dy + size.height * 2, // Немного отступа вниз
      ),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.format_align_left_outlined),
              SizedBox(width: 6),
              Text(HtmlAlignmentType.left.title,
                  style: TextStyle(color: editorColors?.contentColor)),
            ],
          ),
          onTap: () => controller.setAlignment(HtmlAlignmentType.left),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.format_align_center_outlined),
              SizedBox(width: 6),
              Text(HtmlAlignmentType.center.title,
                  style: TextStyle(color: editorColors?.contentColor)),
            ],
          ),
          onTap: () => controller.setAlignment(HtmlAlignmentType.center),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.format_align_right_outlined),
              SizedBox(width: 6),
              Text(HtmlAlignmentType.right.title,
                  style: TextStyle(color: editorColors?.contentColor)),
            ],
          ),
          onTap: () => controller.setAlignment(HtmlAlignmentType.right),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.format_align_justify_outlined),
              SizedBox(width: 6),
              Text(HtmlAlignmentType.justify.title,
                  style: TextStyle(color: editorColors?.contentColor)),
            ],
          ),
          onTap: () => controller.setAlignment(HtmlAlignmentType.justify),
        ),
      ],
    );
  }

}
