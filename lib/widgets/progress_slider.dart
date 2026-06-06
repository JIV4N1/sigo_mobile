import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProgressSlider extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;

  const ProgressSlider({
    super.key,
    this.initialValue = 0,
    required this.onChanged,
  });

  @override
  State<ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<ProgressSlider> {
  late double _currentValue;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.toDouble();
    _controller.text = widget.initialValue.toString();
  }

  Color _getSliderColor() {
    if (_currentValue <= 25) return AppColors.critical;
    if (_currentValue <= 50) return AppColors.accent;
    if (_currentValue <= 75) return const Color(0xFFFFD54F); // Amarillo
    return AppColors.success;
  }

  void _updateFromText(String value) {
    if (value.isEmpty) return;
    int? parsed = int.tryParse(value);
    if (parsed != null) {
      if (parsed < 0) parsed = 0;
      if (parsed > 100) parsed = 100;
      setState(() {
        _currentValue = parsed!.toDouble();
        _controller.text = parsed.toString();
        _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
      });
      widget.onChanged(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getSliderColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 12,
                  activeTrackColor: activeColor,
                  inactiveTrackColor: AppColors.border,
                  thumbColor: activeColor,
                  overlayColor: activeColor.withOpacity(0.2),
                  valueIndicatorColor: activeColor,
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Slider(
                  value: _currentValue,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${_currentValue.toInt()}%',
                  onChanged: (value) {
                    setState(() {
                      _currentValue = value;
                      _controller.text = value.toInt().toString();
                    });
                    widget.onChanged(value.toInt());
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                decoration: InputDecoration(
                  suffixText: '%',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: activeColor, width: 2),
                  ),
                ),
                onChanged: _updateFromText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
