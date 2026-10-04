import 'package:flutter/widgets.dart';

class const OverscrollProvider({
  super.key,
  required final Widget child,
  final ScrollNotificationPredicate notificationPredicate =
      defaultScrollNotificationPredicate,
}) extends StatefulWidget {
  @override
  State<OverscrollProvider> createState() => OverscrollProviderState();

  static OverscrollProviderState? of(BuildContext context) =>
      context.findAncestorStateOfType<OverscrollProviderState>();
}

class OverscrollProviderState extends State<OverscrollProvider> {
  final ValueNotifier<bool> isOverscrolling = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      child: widget.child,
      onNotification: (notification) {
        if (!widget.notificationPredicate(notification)) return false;

        if (notification is OverscrollNotification) {
          isOverscrolling.value = true;
        }

        if (notification is ScrollStartNotification) {
          isOverscrolling.value = false;
        }

        if (notification is ScrollEndNotification) {
          isOverscrolling.value = false;
        }

        return false;
      },
    );
  }
}
