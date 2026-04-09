import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class ExpandableFabAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ExpandableFabAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class ExpandableFab extends StatefulWidget {
  final double bottomOffset;
  final List<ExpandableFabAction> actions;

  const ExpandableFab({
    super.key,
    this.bottomOffset = 16,
    required this.actions,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  OverlayEntry? _scrimEntry;
  OverlayEntry? _actionsEntry;
  final _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _removeOverlays();
    _controller.dispose();
    super.dispose();
  }

  void _insertOverlays() {
    _removeOverlays();
    final overlay = Overlay.of(context, rootOverlay: true);

    _scrimEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        onTap: _close,
        child: Container(color: Colors.black.withValues(alpha: 0.3)),
      ),
    );

    _actionsEntry = OverlayEntry(
      builder: (_) {
        final box = _fabKey.currentContext?.findRenderObject() as RenderBox?;
        if (box == null) return const SizedBox.shrink();
        final pos = box.localToGlobal(Offset.zero);
        final fabRight = MediaQuery.of(context).size.width - pos.dx - box.size.width;

        return Positioned(
          right: fabRight,
          bottom: MediaQuery.of(context).size.height - pos.dy + AppSpacing.sm,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final action in widget.actions) ...[
                  ScaleTransition(
                    scale: _expandAnimation,
                    child: _buildActionButton(action),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        );
      },
    );

    overlay.insert(_scrimEntry!);
    overlay.insert(_actionsEntry!);
  }

  void _removeOverlays() {
    _actionsEntry?.remove();
    _actionsEntry?.dispose();
    _actionsEntry = null;
    _scrimEntry?.remove();
    _scrimEntry?.dispose();
    _scrimEntry = null;
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _insertOverlays();
        _controller.forward();
      } else {
        _removeOverlays();
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isExpanded) {
      _removeOverlays();
      setState(() {
        _isExpanded = false;
        _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actions.isEmpty) return const SizedBox.shrink();

    return Positioned(
      right: 16,
      bottom: widget.bottomOffset,
      child: FloatingActionButton(
        key: _fabKey,
        onPressed: _toggle,
        child: AnimatedRotation(
          turns: _isExpanded ? 0.125 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(_isExpanded ? Icons.close : Icons.add),
        ),
      ),
    );
  }

  Widget _buildActionButton(ExpandableFabAction action) {
    return GestureDetector(
      onTap: () {
        _close();
        action.onTap();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Text(action.label, style: AppTextStyles.body),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: action.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(action.icon, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
