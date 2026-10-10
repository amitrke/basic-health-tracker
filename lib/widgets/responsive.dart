import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Widths where the layout changes.
abstract final class Breakpoints {
  /// From here the tabs move to a side rail.
  static const rail = 600.0;

  /// From here Today shows two columns.
  static const twoColumn = 840.0;

  /// Widest a single column of content gets.
  static const content = 720.0;

  /// Widest the two-column Today gets.
  static const wideContent = 1200.0;
}

/// Side padding that keeps content [maxWidth] wide at most, centred, and
/// never closer than 16 to the edge.
double sideInset(double available, {double maxWidth = Breakpoints.content}) =>
    math.max(16, (available - maxWidth) / 2);

/// A [ListView] whose content stays centred and at most [maxWidth] wide. The
/// list itself still fills the screen, so it scrolls from anywhere.
class CenteredListView extends StatelessWidget {
  const CenteredListView({
    super.key,
    required this.children,
    this.top = 0,
    this.bottom = 32,
    this.maxWidth = Breakpoints.content,
    this.physics,
    this.keyboardDismissBehavior,
  });

  final List<Widget> children;
  final double top;
  final double bottom;
  final double maxWidth;
  final ScrollPhysics? physics;
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final side = sideInset(box.maxWidth, maxWidth: maxWidth);
        return ListView(
          physics: physics,
          keyboardDismissBehavior: keyboardDismissBehavior,
          padding: EdgeInsets.fromLTRB(side, top, side, bottom),
          children: children,
        );
      },
    );
  }
}

/// Centres [child] and caps its width, for screens that are not a list.
class MaxWidth extends StatelessWidget {
  const MaxWidth({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.content,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
