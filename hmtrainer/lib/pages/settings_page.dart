import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.autoSync,
    required this.restSeconds,
    required this.onToggleAutoSync,
    required this.onChangeRestSeconds,
  });

  final bool autoSync;
  final int restSeconds;
  final void Function(bool value) onToggleAutoSync;
  final void Function(int delta) onChangeRestSeconds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('앱 설정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: SwitchListTile(
            title: const Text('자동 동기화', style: TextStyle(color: Colors.black87)),
            value: autoSync,
            activeThumbColor: Colors.red,
            onChanged: onToggleAutoSync,
          ),
        ),
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            title: const Text('휴식 타이머', style: TextStyle(color: Colors.black87)),
            subtitle: Text('$restSeconds초', style: const TextStyle(color: Colors.black54)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.red),
                  onPressed: () => onChangeRestSeconds(-10),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.red),
                  onPressed: () => onChangeRestSeconds(10),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: const ListTile(
            title: Text('앱 정보', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            subtitle: Text('HMT v0.2.1', style: TextStyle(color: Colors.black54)),
          ),
        ),
      ],
    );
  }
}
