import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

const _kEmojis = ['😂', '😅', '👍', '❤️', '😱', '💸'];

class ReactionPicker extends StatelessWidget {
  final void Function(String emoji) onSelected;

  const ReactionPicker({super.key, required this.onSelected});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (_) => ReactionPicker(
        onSelected: (emoji) => Navigator.pop(context, emoji),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _kEmojis.map((emoji) => _EmojiButton(
            emoji: emoji,
            onTap: () => onSelected(emoji),
          )).toList(),
        ),
      ),
    );
  }
}

class _EmojiButton extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiButton({required this.emoji, required this.onTap});

  @override
  State<_EmojiButton> createState() => _EmojiButtonState();
}

class _EmojiButtonState extends State<_EmojiButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _ctrl.forward(from: 0).then((_) => widget.onTap());
      },
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(widget.emoji, style: AppTextStyles.emoji),
        ),
      ),
    );
  }
}
