import 'package:flutter/material.dart';
import 'package:html_editor/editor.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerDialog {
  static Future<void> showDeletionImageDialog(
    BuildContext context,
    String imageUrl,
    IHtmlEditorController controller,
  ) async {
    await _showDialog(
      context,
      children: [
        _buildListTile(
          title: 'Удалить изображение',
          icon: AppIcons.trash,
          iconColor: context.theme.red800,
          onTap: () {
            if (context.mounted) Navigator.of(context).pop();
            controller.deleteImage(imageUrl);
          },
        ),
      ],
    );
  }

  static Future<void> showImagePickerDialog(
    BuildContext context,
    IHtmlEditorController controller,
  ) async {
    await _showDialog(
      context,
      children: [
        Text(
          'Добавить изображение',
          style: AppTextStyle.headlineH18Medium
              .copyWith(color: context.theme.gray800),
        ),
        const SizedBox(height: 16),
        _buildListTile(
          title: 'Сделать фото',
          icon: AppIcons.camera,
          iconColor: context.theme.gray800,
          onTap: () async {
            if (context.mounted) Navigator.of(context).pop();
            await controller.pickImage(ImageSource.camera);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(
            height: 0,
            color: context.theme.gray100,
          ),
        ),
        _buildListTile(
          title: 'Выбрать изображение',
          icon: AppIcons.gallery,
          iconColor: context.theme.gray800,
          onTap: () async {
            if (context.mounted) Navigator.of(context).pop();
            await controller.pickImage(ImageSource.gallery);
          },
        ),
      ],
    );
  }

  static Future<void> _showDialog(
    BuildContext context, {
    required List<Widget> children,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: context.theme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: MediaQuery.of(context).size.width / 6,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  static Widget _buildListTile({
    required String title,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title,
          style: AppTextStyle.headlineH18Regular.copyWith(
            color: iconColor,
          )),
      trailing: Icon(icon, color: iconColor),
      onTap: onTap,
    );
  }
}
