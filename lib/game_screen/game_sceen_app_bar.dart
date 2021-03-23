import 'package:flutter/material.dart';

@immutable
class GameScreenAppBar extends SliverPersistentHeaderDelegate {
  final double expandedHeight;

  GameScreenAppBar({required this.expandedHeight});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(color: Colors.lightBlue),
          child: Align(
            alignment: Alignment.topCenter,
            child: Text("Lost Cities Scoring Helper",
                style: theme.textTheme.headline6!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )),
          ),
        ),
        Placeholder()
      ],
    );
  }

  @override
  double get maxExtent => 200;

  @override
  double get minExtent => kToolbarHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
