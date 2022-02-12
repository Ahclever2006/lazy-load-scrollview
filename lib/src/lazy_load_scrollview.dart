library lazy_load_scrollview;

import 'dart:async';

import 'package:flutter/widgets.dart';

enum LoadingStatus { LOADING, STABLE }

/// Signature for EndOfPageListeners
typedef FutureCallback<T> = FutureOr<T> Function();

/// A widget that wraps a [Widget] and will trigger [onEndOfPage] when it
/// reaches the bottom of the list
class LazyLoadScrollView extends StatefulWidget {
  /// The [Widget] that this widget watches for changes on
  final Widget child;

  /// Called when the [child] reaches the end of the list
  final FutureCallback onEndOfPage;

  /// The offset to take into account when triggering [onEndOfPage] in pixels
  final int scrollOffset;

  /// Prevented update nested listview with other axis direction
  final Axis scrollDirection;

  @override
  State<StatefulWidget> createState() => LazyLoadScrollViewState();

  LazyLoadScrollView({
    Key? key,
    required this.child,
    required this.onEndOfPage,
    this.scrollDirection = Axis.vertical,
    this.scrollOffset = 100,
  }) : super(key: key);
}

class LazyLoadScrollViewState extends State<LazyLoadScrollView> {
  var _loadMoreStatus = LoadingStatus.STABLE;

  @override
  void didUpdateWidget(covariant LazyLoadScrollView oldWidget) {
    if (_loadMoreStatus == LoadingStatus.LOADING)
      _loadMoreStatus = LoadingStatus.STABLE;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      child: widget.child,
      onNotification: (notification) => _onNotification(notification, context),
    );
  }

  bool _onNotification(ScrollNotification notification, BuildContext context) {
    if (widget.scrollDirection == notification.metrics.axis) {
      if (notification is ScrollUpdateNotification) {
        if (notification.metrics.maxScrollExtent >
                notification.metrics.pixels &&
            notification.metrics.maxScrollExtent -
                    notification.metrics.pixels <=
                widget.scrollOffset) {
          _loadMore();
        }
        return true;
      }

      if (notification is OverscrollNotification) {
        if (notification.overscroll > 0) {
          _loadMore();
        }
        return true;
      }
    }
    return false;
  }

  void _loadMore() {
    if (_loadMoreStatus == LoadingStatus.LOADING) return;

    print('load more');
    final futureOr = widget.onEndOfPage();
    _loadMoreStatus = LoadingStatus.LOADING;
    if (futureOr is Future)
      futureOr.whenComplete(() => _loadMoreStatus = LoadingStatus.STABLE);
  }
}
