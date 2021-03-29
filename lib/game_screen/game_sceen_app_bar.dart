import 'dart:ui';

import 'package:flutter/material.dart';

class GameScreenAppBar extends SliverPersistentHeaderDelegate {
  final double expandedHeight;

  GameScreenAppBar({required this.expandedHeight});

  Widget _playerScore(ThemeData theme, TextStyle? style, int playerNumber,
      int score, double collapsedPercent) {
    return Column(
      children: [
        Text(
          "Player $playerNumber",
          style: theme.textTheme.bodyText1!
              .copyWith(color: Colors.white.withOpacity(1 - collapsedPercent)),
        ),
        Text(
          score.toString(),
          style: style,
        )
      ],
    );
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);

    final collapsedPercent =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0, 1).toDouble();
    final textSize = lerpDouble(theme.textTheme.headline3!.fontSize,
        theme.textTheme.headline4!.fontSize, collapsedPercent);
    final sidePadding = lerpDouble(20, 80, collapsedPercent);
    final scoreTextStyle = theme.textTheme.headline3?.copyWith(
      fontSize: textSize,
      color: Colors.white,
    );

    return Container(
      decoration: BoxDecoration(color: Colors.lightBlue),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            padding: EdgeInsets.only(top: 10),
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Text(
                "Lost Cities Scoring Helper",
                style: theme.textTheme.headline6!.copyWith(
                  color: Colors.white.withOpacity(1 - collapsedPercent),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(sidePadding!, 0, sidePadding, 10),
            alignment: Alignment.bottomCenter,
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _playerScore(theme, scoreTextStyle, 1, 100, collapsedPercent),
                  Text("-",
                      style: theme.textTheme.headline3!
                          .copyWith(color: Colors.white)),
                  _playerScore(theme, scoreTextStyle, 2, 450, collapsedPercent),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  double get maxExtent => 230;

  @override
  double get minExtent => kToolbarHeight + 30;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
