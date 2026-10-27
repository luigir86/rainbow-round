import 'package:flutter/material.dart';

/// The gear of the settings, which opens only when held for [hold], so
/// that a child playing does not open it by chance. A ring fills round it
/// while it is held.
class HoldGear extends StatefulWidget {
  const HoldGear({
    super.key,
    required this.label,
    required this.onOpen,
    this.hold = const Duration(seconds: 2),
  });

  /// What a screen reader says; it opens the settings with a long press.
  final String label;
  final VoidCallback onOpen;
  final Duration hold;

  @override
  State<HoldGear> createState() => _HoldGearState();
}

class _HoldGearState extends State<HoldGear>
    with SingleTickerProviderStateMixin {
  late final _progress = AnimationController(vsync: this, duration: widget.hold)
    ..addStatusListener(_done);

  void _done(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _progress.value = 0;
    widget.onOpen();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: widget.label,
      onLongPress: widget.onOpen,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => _progress.forward(from: 0),
        onPointerUp: (_) => _progress.value = 0,
        onPointerCancel: (_) => _progress.value = 0,
        child: SizedBox.square(
          dimension: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _progress,
                builder: (context, _) => SizedBox.square(
                  dimension: 44,
                  child: CircularProgressIndicator(
                    value: _progress.value,
                    strokeWidth: 3,
                    color: scheme.primary,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              Icon(Icons.settings_rounded, color: scheme.outline, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
