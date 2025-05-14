import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

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
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MaterialAction(
                title: 'Открыть',
                icon: Icons.language_sharp,
                onPressed: () =>
                    Navigator.of(context).pop(LinkMenuAction.launch),
              ),
              _MaterialAction(
                title: 'Копировать',
                icon: Icons.copy_sharp,
                onPressed: () => Navigator.of(context).pop(LinkMenuAction.copy),
              ),
              _MaterialAction(
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
  });

  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        size: theme.iconTheme.size,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
      ),
      title: Text(title),
      onTap: onPressed,
    );
  }
}
