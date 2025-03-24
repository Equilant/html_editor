import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled100/src/html_editor_controller.dart';

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
          icon: Icons.delete,
          iconColor: Colors.red,
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
        const Text(
          'Добавить изображение',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        _buildListTile(
          title: 'Сделать фото',
          icon: Icons.camera_alt,
          onTap: () async {
            if (context.mounted) Navigator.of(context).pop();
            await controller.pickImage(ImageSource.camera);
          },
        ),
        const Divider(height: 0),
        _buildListTile(
          title: 'Выбрать изображение',
          icon: Icons.image,
          onTap: () async {
            if (context.mounted) Navigator.of(context).pop();
            await controller.pickImage(ImageSource.gallery);
          },
        ),
      ],
    );
  }

  static Future<void> _showDialog(BuildContext context,
      {required List<Widget> children}) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Icon(icon, color: iconColor),
      onTap: onTap,
    );
  }
}
