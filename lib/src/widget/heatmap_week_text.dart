import 'package:flutter/material.dart';
import '../util/date_util.dart';

class HeatMapWeekText extends StatelessWidget {
  /// The margin value for correctly space between labels.
  final EdgeInsets? margin;

  /// The double value of label's font size.
  final double? fontSize;

  /// The double value of every block's size to fit the height.
  final double? size;

  /// The color value of every font's color.
  final Color? fontColor;

  const HeatMapWeekText({
    super.key,
    this.margin,
    this.fontSize,
    this.size,
    this.fontColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: DateUtil.WEEK_LABEL.map((day) {
        return Container(
            height: size ?? 20,
            margin: margin ?? const EdgeInsets.all(2.0),
            child: Text(
              day['label']!,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: fontSize ?? 12,
                color: fontColor ?? (day['color'] == 'red' ? Colors.red : Theme.of(context).colorScheme.inverseSurface),
              ),
            )
        );
      }).toList(),
    );
  }
}