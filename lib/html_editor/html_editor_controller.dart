import 'dart:convert';
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

abstract interface class IHtmlEditorController {
  void dispose();

  QuillController get quillController;

  void convertDeltaToHtml();

  Future<void> insertFileFromStorage();

  Future<void> openFileOrLink(String url);

  Future<void> replaceLocalFilesWithLinks();
}

class HtmlEditorController implements IHtmlEditorController {
  late final QuillController _controller;
  final String html;

  HtmlEditorController({required this.html}) {
    _controller = QuillController.basic(
        config: QuillControllerConfig(
      clipboardConfig: QuillClipboardConfig(
        enableExternalRichPaste: true,
        onImagePaste: (imageBytes) async {
          // Save the image somewhere and return the image URL that will be
          // stored in the Quill Delta JSON (the document).
          final newFileName =
              'image-file-${DateTime.now().toIso8601String()}.png';
          final newPath = path.join(
            io.Directory.systemTemp.path,
            newFileName,
          );
          final file = await io.File(
            newPath,
          ).writeAsBytes(imageBytes, flush: true);
          return file.path;
        },
      ),
    ));

    var delta = HtmlToDelta().convert(html);

    _controller.document = Document.fromDelta(delta);
  }

  @override
  void dispose() {
    _controller.dispose();
  }

  String sanitizeFileName(String name) {
    final String normalized = name
        .replaceAll(RegExp(r'\s+'), '_') // Заменяем пробелы на "_"
        .replaceAll(RegExp(r'[^\w\-.]'), '') // Убираем недопустимые символы
        .toLowerCase();

    return normalized;
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

  // @override
  // Future<void> insertFileFromStorage() async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles();
  //   if (result != null && result.files.isNotEmpty) {
  //     final file = result.files.first;
  //     final fileName = file.name;
  //     final filePath = file.path;
  //     if (filePath != null) {
  //       final index = _controller.selection.baseOffset;
  //       // Вставляем название файла
  //       _controller.document.insert(index, fileName);
  //       // Форматируем вставленный текст как ссылку на файл
  //       _controller.formatText(
  //         index,
  //         fileName.length,
  //         Attribute<String>('link', AttributeScope.inline, filePath),
  //       );
  //     }
  //   }
  // }

  Future<String> uploadFileToServer(String localPath) async {
    final file = io.File(localPath);
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
}
