import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../cardio_duration.dart';

class CardioDurationPicker extends StatelessWidget {
  const CardioDurationPicker({
    super.key,
    required this.durationSeconds,
    required this.onChanged,
  });

  final int durationSeconds;
  final ValueChanged<int> onChanged;

  Future<void> _showPicker(BuildContext context) async {
    final duration = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          _CardioDurationPickerSheet(initialSeconds: durationSeconds),
    );
    if (duration != null) onChanged(duration);
  }

  @override
  Widget build(BuildContext context) {
    final parts = CardioDuration.partsFor(durationSeconds);
    final display = durationSeconds <= 0
        ? '시간 · 분 · 초 설정'
        : '${parts[0]}시간  ${parts[1]}분  ${parts[2]}초';

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        key: const Key('cardio_duration_picker_button'),
        onPressed: () => _showPicker(context),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          foregroundColor: Colors.black87,
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 20, color: Colors.black54),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                display,
                style: TextStyle(
                  color: durationSeconds <= 0
                      ? Colors.grey.shade600
                      : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

class _CardioDurationPickerSheet extends StatefulWidget {
  const _CardioDurationPickerSheet({required this.initialSeconds});

  final int initialSeconds;

  @override
  State<_CardioDurationPickerSheet> createState() =>
      _CardioDurationPickerSheetState();
}

class _CardioDurationPickerSheetState
    extends State<_CardioDurationPickerSheet> {
  late final List<int> _values;
  late final List<FixedExtentScrollController> _controllers;

  static const _labels = ['시간', '분', '초'];
  static const _maxValues = [
    CardioDuration.maxHours,
    CardioDuration.maxMinutes,
    CardioDuration.maxSeconds,
  ];

  @override
  void initState() {
    super.initState();
    _values = CardioDuration.partsFor(
      widget.initialSeconds,
    ).map((part) => int.tryParse(part) ?? 0).toList();
    _controllers = List<FixedExtentScrollController>.generate(
      _values.length,
      (index) => FixedExtentScrollController(initialItem: _values[index]),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  int get _totalSeconds => _values[0] * 3600 + _values[1] * 60 + _values[2];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Row(
              children: [
                TextButton(
                  key: const Key('cardio_duration_cancel'),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                const Expanded(
                  child: Text(
                    '운동 시간',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('cardio_duration_done'),
                  onPressed: () => Navigator.pop(context, _totalSeconds),
                  child: const Text('완료'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: Row(
              children: List<Widget>.generate(_labels.length, (column) {
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        _labels[column],
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          key: Key('cardio_${_labels[column]}_picker'),
                          backgroundColor: Colors.white,
                          scrollController: _controllers[column],
                          itemExtent: 44,
                          useMagnifier: true,
                          magnification: 1.08,
                          selectionOverlay:
                              const CupertinoPickerDefaultSelectionOverlay(
                                background: Color(0x14C62828),
                              ),
                          onSelectedItemChanged: (value) {
                            setState(() => _values[column] = value);
                          },
                          children: List<Widget>.generate(
                            _maxValues[column] + 1,
                            (value) => Center(
                              child: Text(
                                value.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
