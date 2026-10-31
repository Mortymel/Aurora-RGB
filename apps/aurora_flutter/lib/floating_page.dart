import 'package:flutter/material.dart';

/// One floating surface; forms navigate inside it rather than stacking dialogs.
class DeviceWindowScope extends InheritedWidget {
  const DeviceWindowScope({
    super.key,
    required this.close,
    required super.child,
  });
  final VoidCallback close;
  static DeviceWindowScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DeviceWindowScope>();
  @override
  bool updateShouldNotify(DeviceWindowScope oldWidget) =>
      close != oldWidget.close;
}

Route<T> windowRoute<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
  transitionDuration: Duration.zero,
  reverseTransitionDuration: Duration.zero,
  pageBuilder: (context, animation, secondaryAnimation) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: builder(context),
  ),
);

Future<T?> floatingPage<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  if (DeviceWindowScope.of(context) != null) {
    return Navigator.of(context).push<T>(windowRoute<T>(builder));
  }
  return showDialog<T>(
    context: context,
    useSafeArea: true,
    builder: (context) => Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.sizeOf(context).height * .86,
        ),
        child: builder(context),
      ),
    ),
  );
}

class WindowHeading extends StatelessWidget {
  const WindowHeading({super.key, required this.title, this.busy = false});
  final String title;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final scope = DeviceWindowScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          if (scope != null && Navigator.of(context).canPop())
            IconButton(
              tooltip: 'Volver atrás',
              onPressed: busy ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: busy
                ? null
                : scope?.close ?? () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
