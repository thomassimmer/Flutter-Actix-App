import 'package:flutter/material.dart';
import 'package:flutteractixapp/core/ui/extensions.dart';

class SuccessfulLoginAnimation extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onAnimationComplete;

  const SuccessfulLoginAnimation({
    Key? key,
    required this.isVisible,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  SuccessfulLoginAnimationState createState() =>
      SuccessfulLoginAnimationState();
}

class SuccessfulLoginAnimationState extends State<SuccessfulLoginAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _strokeWidthAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    // Scale animation for the circle
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut, // Smooth elastic scale effect
    );

    // Stroke width animation for the circle (starts thin, grows thicker)
    _strokeWidthAnimation = Tween<double>(begin: 2, end: 6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Fade-in animation for the icon
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    if (widget.isVisible) {
      _controller.forward();
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SuccessfulLoginAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible) {
      _controller.forward();
    } else {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isVisible
        ? Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle glow/pulse effect behind the circle
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          context.colors.primary.withOpacity(0.2),
                          Colors.transparent
                        ],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // Animated bare circle
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedBuilder(
                      animation: _strokeWidthAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.colors.primary,
                              width: _strokeWidthAnimation.value,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          )
        : SizedBox.shrink();
  }
}
