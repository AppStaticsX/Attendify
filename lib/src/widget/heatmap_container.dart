import 'package:flutter/material.dart';
import '../data/heatmap_color.dart';

class HeatMapContainer extends StatelessWidget {
  final DateTime date;
  final double? size;
  final double? fontSize;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? textColor;
  final EdgeInsets? margin;
  final bool? showText;
  final Function(DateTime dateTime)? onClick;

  const HeatMapContainer({
    super.key,
    required this.date,
    this.margin,
    this.size,
    this.fontSize,
    this.borderRadius,
    this.backgroundColor,
    this.selectedColor,
    this.textColor,
    this.onClick,
    this.showText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.all(2),
      child: GestureDetector(
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? HeatMapColor.defaultColor,
            borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 5)),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutQuad,
            width: 32,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selectedColor,
              borderRadius:
                  BorderRadius.all(Radius.circular(borderRadius ?? 5)),
            ),
            child: (showText ?? true)
                ? Text(
                    date.day.toString(),
                    style: TextStyle(
                        color: textColor ?? Theme.of(context).colorScheme.inverseSurface,
                        fontSize: fontSize),
                  )
                : null,
          ),
        ),
        onTap: () {
          onClick != null ? onClick!(date) : null;
        },
      ),
    );
  }
}
