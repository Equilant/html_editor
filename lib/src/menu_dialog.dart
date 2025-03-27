import 'package:flutter/material.dart';
import 'package:untitled100/editor.dart';

class MenuDialog {
  static Future<void> showAlignmentMenu(
    BuildContext context,
    IHtmlEditorController controller,
    GlobalKey iconKey,
  ) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RenderBox renderBox =
        iconKey.currentContext?.findRenderObject() as RenderBox;
    final Offset offset =
        renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final Size size = renderBox.size;

    final iconColor = context.theme.gray800;

    final textStyle = AppTextStyle.textT14Regular.copyWith(
      color: iconColor,
    );

    showMenu(
      context: context,
      color: context.theme.bg,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy + size.height * 2,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.format_align_left_outlined, color: iconColor),
              SizedBox(width: 6),
              Text(HtmlAlignmentType.left.title, style: textStyle),
            ],
          ),
          onTap: () => controller.setAlignment(HtmlAlignmentType.left),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                Icons.format_align_center_outlined,
                color: iconColor,
              ),
              SizedBox(width: 6),
              Text(HtmlAlignmentType.center.title, style: textStyle),
            ],
          ),
          onTap: () => controller.setAlignment(HtmlAlignmentType.center),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                Icons.format_align_right_outlined,
                color: iconColor,
              ),
              SizedBox(width: 6),
              Text(HtmlAlignmentType.right.title, style: textStyle),
            ],
          ),
          onTap: () => controller.setAlignment(HtmlAlignmentType.right),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                Icons.format_align_justify_outlined,
                color: iconColor,
              ),
              SizedBox(width: 6),
              Text(HtmlAlignmentType.justify.title, style: textStyle),
            ],
          ),
          onTap: () => controller.setAlignment(HtmlAlignmentType.justify),
        ),
      ],
    );
  }
}
