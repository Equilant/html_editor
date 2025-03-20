import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'dart:io' as io show Directory, File;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as leaf;

abstract interface class IHtmlEditorController {
  void dispose();

  QuillController get quillController;

  void convertDeltaToHtml();

  Future<void> insertFileFromStorage();

  Future<void> openFileOrLink(String url);

  Future<void> replaceLocalFilesWithLinks();

  Future<void> replaceLocalImagesWithLinks();

  Future<void> pickImage(ImageSource imageSource);

  ImageProvider<Object>? imageProviderBuilder(
      BuildContext context, String path);

  void deleteImage(String imageUrl);
}

class HtmlEditorController implements IHtmlEditorController {
  late final QuillController _controller;
  final String html;

  HtmlEditorController({required this.html}) {
    _controller = QuillController.basic(
        config: QuillControllerConfig(
      clipboardConfig: QuillClipboardConfig(
        enableExternalRichPaste: true,
        onImagePaste: onImagePasteHandler,
      ),
    ));

    var delta = HtmlToDelta().convert(html);

    _controller.document = Document.fromDelta(delta);
  }

  @override
  void dispose() {
    _controller.dispose();
  }

  // Future<String?> uploadImageToServer(String filePath) async {
  //   final file = io.File(filePath);
  //   if (!file.existsSync()) return null;
  //
  //   final uri = Uri.parse("https://ваш-сервер.com/upload"); // Укажите свой сервер
  //   final mimeType = lookupMimeType(filePath) ?? 'image/png';
  //
  //   final request = http.MultipartRequest('POST', uri)
  //     ..files.add(await http.MultipartFile.fromPath('file', file.path))
  //     ..headers['Content-Type'] = mimeType;
  //
  //   try {
  //     final response = await request.send();
  //     if (response.statusCode == 200) {
  //       final responseBody = await response.stream.bytesToString();
  //       return extractImageUrl(responseBody); // Функция для получения ссылки из ответа
  //     } else {
  //       print("Ошибка загрузки: ${response.statusCode}");
  //       return null;
  //     }
  //   } catch (e) {
  //     print("Ошибка сети: $e");
  //     return null;
  //   }
  // }

  Future<String> onImagePasteHandler(Uint8List imageBytes) async {
    // Получаем директорию для хранения
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'pasted_image_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = path.join(directory.path, fileName);

    // Сохраняем изображение в локальное хранилище
    final file = io.File(filePath);
    await file.writeAsBytes(imageBytes);

    // Вставляем локальный путь в редактор (он будет заменен позже)
    return 'file://$filePath';
  }

  @override
  Future<void> insertFileFromStorage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final fileName = file.name;
      final filePath = file.path;

      if (filePath != null) {
        // Перемещаем файл в локальную папку приложения
        final directory = await getApplicationDocumentsDirectory();
        final newPath = path.join(directory.path, fileName);
        final localFile = await io.File(filePath).copy(newPath);

        final index = _controller.selection.baseOffset;

        // Вставляем название файла
        _controller.document.insert(index, fileName);

        // Форматируем вставленный текст как ссылку (локальный путь)
        _controller.formatText(
          index,
          fileName.length,
          Attribute<String>(
              'link', AttributeScope.inline, 'file://${localFile.path}'),
        );
      }
    }
  }

  Future<String> uploadFileToServer(String localPath) async {
    final file = io.File(removeFilePrefix(localPath));
    final uri = Uri.parse(
        "https://local.dev.k8s.umschool.dev/froala_editor/file_upload/");

    if (!file.existsSync()) {
      return '';
    }

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        // contentType: MediaType('application', 'pdf'), // Укажи нужный MIME-тип
        contentType: _getMediaType(mimeType),
      ))
      //..headers['Content-Disposition'] = 'inline; filename="${path.basename(file.path)}"'; // Важно!
      ..headers['Content-Type'] = mimeType;

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData);
      return json['link']; // URL загруженного файла
    } else {
      throw Exception("Ошибка загрузки файла");
    }
  }

  // Функция преобразует MIME-тип в формат MediaType для http.MultipartFile
  MediaType _getMediaType(String mimeType) {
    final parts = mimeType.split('/');
    if (parts.length == 2) {
      return MediaType(parts[0], parts[1]);
    }
    return MediaType('application', 'octet-stream');
  }

  @override
  Future<void> replaceLocalImagesWithLinks() async {
    final delta = _controller.document.toDelta();
    int index = 0;

    for (var op in delta.toList()) {
      if (op.data is Map && (op.data as Map).containsKey('image')) {
        final localPath = (op.data as Map)['image'];

        if (localPath.startsWith('file://')) {
          // Локальный путь (без 'file://')
          try {
            final uploadedUrl = await uploadFileToServer(localPath);

            // Заменяем локальный путь на ссылку в редакторе
            _controller.replaceText(
              index,
              1, // Заменяем 1 элемент
              BlockEmbed.image(uploadedUrl), // Передаем корректный объект
              null,
            );
          } catch (e) {
            debugPrint("Ошибка загрузки изображения: $e");
          }
        }
      }

      // Увеличиваем index на длину текущей операции
      index += op.length ?? 0;
    }
  }

  @override
  Future<void> replaceLocalFilesWithLinks() async {
    final delta = _controller.document.toDelta();
    int currentOffset = 0;

    for (var op in delta.toList()) {
      final opLength = op.length ?? op.data.toString().length;

      if (op.attributes != null && op.attributes!['link'] != null) {
        final link = op.attributes!['link'];

        if (link.startsWith('file://')) {
          final filePath = link.replaceFirst('file://', '');

          try {
            final uploadedUrl = await uploadFileToServer(filePath);

            // Обновляем ссылку в редакторе
            _controller.formatText(
              currentOffset,
              opLength,
              Attribute<String>('link', AttributeScope.inline, uploadedUrl),
            );
          } catch (e) {
            debugPrint("Ошибка загрузки файла: $e");
          }
        }
      }

      // Увеличиваем текущую позицию на длину операции
      currentOffset += opLength;
      convertDeltaToHtml();
    }
  }

  @override
  Future<void> openFileOrLink(String url) async {
    if (url.startsWith('https://') || url.startsWith('http://')) {
      // Проверяем, является ли это ссылкой на локальный файл
      if (url.startsWith('https://file://') ||
          url.startsWith('http://file://')) {
        final localPath = url.replaceFirst(RegExp(r'^https?://file://'), '');

        if (await io.File(localPath).exists()) {
          await OpenFile.open(localPath);
        } else {
          debugPrint("Файл не найден: $localPath");
        }
        return;
      }

      // Декодируем URL (убираем лишние кодировки)
      final decodedUrl = Uri.decodeFull(url);
      // Заменяем пробелы на %20 вручную
      // Обычная веб-ссылка
      final uri = Uri.parse(decodedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    }

    // Если путь сразу начинается с `file://`, убираем префикс
    if (url.startsWith('file://')) {
      url = url.replaceFirst('file://', '');
    }

    if (await io.File(url).exists()) {
      await OpenFile.open(url);
    } else {
      debugPrint("Файл не найден: $url");
    }
  }

  @override
  QuillController get quillController => _controller;

  @override
  void convertDeltaToHtml() {
    final converter = QuillDeltaToHtmlConverter(
      _controller.document.toDelta().toJson(),
    );
    final html = converter.convert();

    print(html);
  }

  // @override
  // Future<void> pickFile() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  //
  //   if (image != null) await _insertImageIntoEditor(File(image.path));
  //
  // }
  //
  // Future<void> _insertImageIntoEditor(File file) async {
  //   final uploadedUrl = await uploadImage(file); // Загружаем файл и получаем URL
  //   final index = _controller.selection.baseOffset;
  //
  //   _controller.document.insert(index, BlockEmbed.image(uploadedUrl));
  // }

  @override
  Future<void> pickImage(ImageSource imageSource) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: imageSource);

    if (image != null) {
      final filePath = image.path;

      if (filePath != null) {
        try {
          // Получаем директорию для хранения
          final directory = await getApplicationDocumentsDirectory();
          final newPath = path.join(directory.path, path.basename(filePath));

          //  Проверяем, существует ли исходный файл
          final originalFile = io.File(filePath);
          if (!await originalFile.exists()) {
            debugPrint("Файл не найден: $filePath");
            return;
          }

          // Копируем файл в локальное хранилище
          final localFile = await originalFile.copy(newPath);

          //  Проверяем, скопировался ли файл
          if (!await localFile.exists()) {
            debugPrint("Ошибка копирования файла: $newPath");
            return;
          }

          // Формируем корректный путь
          final localImagePath = 'file://${localFile.path}';

          // Вставляем картинку в редактор
          final index = _controller.selection.baseOffset;
          _controller.document.insert(index, BlockEmbed.image(localImagePath));

          // Уведомляем редактор об изменениях
          _controller.updateSelection(
            TextSelection.collapsed(offset: index + 1),
            ChangeSource.local,
          );

          debugPrint("Изображение успешно вставлено: $localImagePath");
        } catch (e) {
          debugPrint("Ошибка вставки изображения: $e");
        }
      }
    }
  }

  @override
  ImageProvider<Object>? imageProviderBuilder(
      BuildContext context, String path) {
    // https://pub.dev/packages/flutter_quill_extensions#-image-assets
    if (path.startsWith('file:/')) {
      String cleanedPath = removeFilePrefix(path);
      return FileImage(io.File(cleanedPath));
    }
    return null;
  }

  String removeFilePrefix(String path) {
    if (path.startsWith('file://')) {
      return path.replaceFirst('file://', '');
    }
    return path;
  }

  @override
  void deleteImage(String imageUrl) {
    final delta = _controller.document.toDelta();
    int index = 0;

    for (var op in delta.toList()) {
      if (op.data is Map && (op.data as Map).containsKey('image')) {
        final localPath = (op.data as Map)['image'];

        // Проверяем, что путь совпадает с тем, который хотим удалить
        if (localPath == imageUrl) {
          try {
            _controller.replaceText(
              index,
              1,
              '',
              TextSelection.collapsed(offset: index),
            );
            return; // Выходим из цикла, удалив нужную картинку
          } catch (e) {
            debugPrint("Ошибка удаления изображения: $e");
          }
        }
      }

      // Увеличиваем index на длину текущей операции
      index += op.length ?? 0;
    }
  }

}
