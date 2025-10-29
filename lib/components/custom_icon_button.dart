import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final Color? iconColor;
  final VoidCallback onPressed;
  final String toolTip;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.size,
    this.color,
    this.iconColor,
    required this.toolTip
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color?? Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(100)
      ),
      child: IconButton(
          tooltip: toolTip,
          onPressed: onPressed,
          icon: Icon(icon,
          size: size,
            color: iconColor,
          )
      ),
    );
  }
}
