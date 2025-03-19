import 'package:flutter/material.dart';
import 'package:untitled100/html_editor/html_editor_controller.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerDialog {
  static Future<bool?> showImagePickerDialog(
    BuildContext context,
    IHtmlEditorController controller,
  ) async =>
      await showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: MediaQuery.of(context).size.width / 6,
                        height: 4,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Добавить изображение',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          'Сделать фото',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: Icon(
                          Icons.camera_alt,
                        ),
                        onTap: () async {
                          if (context.mounted) Navigator.of(context).pop();

                          await controller.pickImage(ImageSource.camera);
                        },
                      ),
                      const Divider(
                        height: 0,
                      ),
                      ListTile(
                        title: Text(
                          'Выбрать изображение',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: Icon(
                          Icons.image,
                        ),
                        onTap: () async {
                          if (context.mounted) Navigator.of(context).pop();

                          await controller.pickImage(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                ),
              ));
}
