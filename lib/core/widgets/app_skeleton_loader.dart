import 'package:flutter/material.dart';

class AppSkeletonLoader extends StatefulWidget {
  const AppSkeletonLoader._({
    super.key,
    required this.height,
    required this.width,
    required this.borderRadius,
  });

  final double height;
  final double? width;
  final double borderRadius;

  /// Single card-shaped skeleton item.
  static Widget listItem({double height = 72, Key? key}) {
    return AppSkeletonLoader._(
      key: key,
      height: height,
      width: double.infinity,
      borderRadius: 12,
    );
  }

  /// A column of [count] skeleton items separated by small gaps.
  /// Automatically reduces count to fit bounded-height parents.
  static Widget list({int count = 6, double itemHeight = 72}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int visibleCount = count;
        if (constraints.maxHeight.isFinite) {
          final maxItems =
              ((constraints.maxHeight + 8) / (itemHeight + 8)).floor();
          visibleCount = maxItems.clamp(1, count);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            visibleCount,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: i < visibleCount - 1 ? 8 : 0),
              child: AppSkeletonLoader._(
                height: itemHeight,
                width: double.infinity,
                borderRadius: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<AppSkeletonLoader> createState() => _AppSkeletonLoaderState();
}

class _AppSkeletonLoaderState extends State<AppSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surfaceContainerHigh;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}
