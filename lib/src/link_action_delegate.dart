import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_editor/editor.dart';

class LinkActionDelegate {
  static Future<LinkMenuAction> customLinkActionPickerDelegate(
      BuildContext context, String link, Node node) async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _showCupertinoLinkMenu(context, link);
      case TargetPlatform.android:
        return _showMaterialMenu(context, link);
      default:
        return LinkMenuAction.none;
    }
  }

  static Future<LinkMenuAction> _showCupertinoLinkMenu(
      BuildContext context, String link) async {
    final result = await showCupertinoModalPopup<LinkMenuAction>(
      useRootNavigator: false,
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: CupertinoActionSheet(
            title: Text(link),
            actions: [
              _CupertinoAction(
                title: 'Открыть',
                icon: Icons.language_sharp,
                onPressed: () =>
                    Navigator.of(context).pop(LinkMenuAction.launch),
              ),
              _CupertinoAction(
                title: 'Копировать',
                icon: Icons.copy_sharp,
                onPressed: () => Navigator.of(context).pop(LinkMenuAction.copy),
              ),
              _CupertinoAction(
                title: 'Удалить',
                icon: Icons.link_off_sharp,
                onPressed: () =>
                    Navigator.of(context).pop(LinkMenuAction.remove),
              ),
            ],
          ),
        );
      },
    );
    return result ?? LinkMenuAction.none;
  }

  static Future<LinkMenuAction> _showMaterialMenu(
      BuildContext context, String link) async {
    final result = await showModalBottomSheet<LinkMenuAction>(
      context: context,
      backgroundColor: context.editorTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: MediaQuery.of(context).size.width / 6,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 16),
              _MaterialAction(
                title: 'Открыть',
                icon: Icons.language_sharp,
                color: context.editorTheme.gray800,
                onPressed: () =>
                    Navigator.of(context).pop(LinkMenuAction.launch),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 0,
                  color: context.editorTheme.gray100,
                ),
              ),
              _MaterialAction(
                title: 'Копировать',
                icon: Icons.copy_sharp,
                color: context.editorTheme.gray800,
                onPressed: () => Navigator.of(context).pop(LinkMenuAction.copy),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 0,
                  color: context.editorTheme.gray100,
                ),
              ),
              _MaterialAction(
                title: 'Удалить',
                icon: Icons.link_off_sharp,
                color: context.editorTheme.gray800,
                onPressed: () =>
                    Navigator.of(context).pop(LinkMenuAction.remove),
              ),
            ],
          ),
        );
      },
    );

    return result ?? LinkMenuAction.none;
  }
}

class _CupertinoAction extends StatelessWidget {
  const _CupertinoAction({
    required this.title,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CupertinoActionSheetAction(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.start,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
            Icon(
              icon,
              size: theme.iconTheme.size,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            )
          ],
        ),
      ),
    );
  }
}

class _MaterialAction extends StatelessWidget {
  const _MaterialAction({
    required this.title,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  final String title;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 80,
      title: Text(
        title,
        style: AppTextStyle.headlineH18Regular.copyWith(
          color: color,
        ),
      ),
      trailing: Icon(
        icon,
        color: color,
      ),
      onTap: onPressed,
    );
  }
}
