import 'package:flutter/material.dart';
import 'package:untitled100/html_editor.dart';
import 'package:untitled100/src/html_editor_controller.dart';

class MenuDialog {
  static Future<void> showAlignmentMenu(BuildContext context,
      IHtmlEditorController controller, EditorColors? editorColors) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      color: editorColors?.backgroundColor,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          overlay.localToGlobal(Offset.zero),
          overlay.localToGlobal(Offset.zero),
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            spacing: 6,
            children: [
              Icon(Icons.format_align_left_outlined),
              Text(
                HtmlAlignmentType.left.title,
                style: TextStyle(color: editorColors?.contentColor),
              )
            ],
          ),
          onTap: () => controller.setAlignment(HtmlAlignmentType.left),
        ),
        PopupMenuItem(
          child: Row(
            spacing: 6,
            children: [
              Icon(Icons.format_align_center_outlined),
              Text(HtmlAlignmentType.center.title,
                  style: TextStyle(color: editorColors?.contentColor))
            ],
          ),
          onTap: () => controller.setAlignment(HtmlAlignmentType.center),
        ),
        PopupMenuItem(
          child: Row(
            spacing: 6,
            children: [
              Icon(Icons.format_align_right_outlined),
              Text(HtmlAlignmentType.right.title,
                  style: TextStyle(color: editorColors?.contentColor))
            ],
          ),
          onTap: () => controller.setAlignment(HtmlAlignmentType.right),
        ),
        PopupMenuItem(
          child: Row(
            spacing: 6,
            children: [
              Icon(Icons.format_align_justify_outlined),
              Text(HtmlAlignmentType.justify.title,
                  style: TextStyle(color: editorColors?.contentColor))
            ],
          ),
          onTap: () => controller.setAlignment(HtmlAlignmentType.justify),
        ),
      ],
    );
  }
}
