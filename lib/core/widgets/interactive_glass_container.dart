import 'package:flutter/material.dart';
import 'dart:ui';

class InteractiveGlassContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final double scaleOnTap;
  final bool useBlur;

  const InteractiveGlassContainer({
    Key? key,
    required this.child,
    this.onTap,
    this.borderRadius = 20,
    this.blur = 10,
    this.color,
    this.border,
    this.padding,
    this.scaleOnTap = 0.95,
    this.useBlur = true,
  }) : super(key: key);

  @override
  State<InteractiveGlassContainer> createState() => _InteractiveGlassContainerState();
}

class _InteractiveGlassContainerState extends State<InteractiveGlassContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleOnTap).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color ?? Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.border ?? Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: widget.child,
    );

    if (widget.useBlur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: content,
        ),
      );
    } else {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: content,
      );
    }

    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: content,
        ),
      ),
    );
  }
}
