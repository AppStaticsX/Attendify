import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final Color? iconColor;
  final VoidCallback onPressed;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.size,
    this.color,
    this.iconColor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color?? Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(100)
      ),
      child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon,
          size: size,
            color: iconColor,
          )
      ),
    );
  }
}
