import 'package:flutter/material.dart';

class ExpandingSection extends StatefulWidget {
  final Widget child;
  final bool expand;
  ExpandingSection({this.expand = false, required this.child});

  @override
  State<StatefulWidget> createState() => _ExpandingSectionState();
}

class _ExpandingSectionState extends State<ExpandingSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    prepareAnimations();
    _runExpandCheck();
  }

  ///Setting up the animation
  void prepareAnimations() {
    _expandController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _animation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.fastOutSlowIn,
    );
  }

  void _runExpandCheck() {
    if (widget.expand) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  void didUpdateWidget(ExpandingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _runExpandCheck();
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
        axisAlignment: 1.0, sizeFactor: _animation, child: widget.child);
  }
}
