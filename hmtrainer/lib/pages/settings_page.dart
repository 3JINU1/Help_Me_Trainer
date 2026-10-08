import 'package:flutter/material.dart';

import 'workout_provider.dart';

String _formatRestTime(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  if (minutes >= 60) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}시간 ${remainingMinutes}분 ${seconds}초';
  }
  if (seconds == 0) return '$minutes분';
  return '$minutes분 ${seconds}초';
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.restTimerSettings,
    required this.onChangeRestTimerSettings,
  });

  final RestTimerSettings restTimerSettings;
  final Future<void> Function(RestTimerSettings settings)
  onChangeRestTimerSettings;

  void _changeInitialSeconds(int delta) {
    final initialSeconds = (restTimerSettings.initialSeconds + delta)
        .clamp(
          RestTimerSettings.minimumInitialSeconds,
          RestTimerSettings.maximumInitialSeconds,
        )
        .toInt();
    var previousSeconds = initialSeconds;
    final adjustedAlerts = <int>[];
    for (final alertSeconds in restTimerSettings.alertSeconds) {
      final adjustedSeconds = alertSeconds <
              previousSeconds + RestTimerSettings.minimumAlertGapSeconds
          ? previousSeconds + RestTimerSettings.minimumAlertGapSeconds
          : alertSeconds;
      if (adjustedSeconds > RestTimerSettings.maximumAlertSeconds) break;
      adjustedAlerts.add(adjustedSeconds);
      previousSeconds = adjustedSeconds;
    }
    onChangeRestTimerSettings(
      RestTimerSettings(
        initialSeconds: initialSeconds,
        alertSeconds: adjustedAlerts,
      ),
    );
  }

  void _changeAlertSeconds(int index, int delta) {
    final previousSeconds = index == 0
        ? restTimerSettings.initialSeconds
        : restTimerSettings.alertSeconds[index - 1];
    final minimumSeconds =
        previousSeconds + RestTimerSettings.minimumAlertGapSeconds;
    final maximumSeconds = index + 1 < restTimerSettings.alertSeconds.length
        ? restTimerSettings.alertSeconds[index + 1] -
              RestTimerSettings.minimumAlertGapSeconds
        : RestTimerSettings.maximumAlertSeconds;
    final alerts = List<int>.of(restTimerSettings.alertSeconds);
    alerts[index] = (alerts[index] + delta)
        .clamp(minimumSeconds, maximumSeconds)
        .toInt();
    onChangeRestTimerSettings(
      restTimerSettings.copyWith(alertSeconds: alerts),
    );
  }

  void _addAlert() {
    final previousSeconds = restTimerSettings.alertSeconds.isEmpty
        ? restTimerSettings.initialSeconds
        : restTimerSettings.alertSeconds.last;
    final nextSeconds =
        previousSeconds + RestTimerSettings.minimumAlertGapSeconds;
    if (nextSeconds > RestTimerSettings.maximumAlertSeconds) return;
    onChangeRestTimerSettings(
      restTimerSettings.copyWith(
        alertSeconds: [...restTimerSettings.alertSeconds, nextSeconds],
      ),
    );
  }

  void _removeAlert(int index) {
    final alerts = List<int>.of(restTimerSettings.alertSeconds)
      ..removeAt(index);
    onChangeRestTimerSettings(
      restTimerSettings.copyWith(alertSeconds: alerts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastAlertSeconds = restTimerSettings.alertSeconds.isEmpty
        ? restTimerSettings.initialSeconds
        : restTimerSettings.alertSeconds.last;
    const nextAlertIntervalSeconds = RestTimerSettings.minimumAlertGapSeconds;
    final canAddAlert =
        lastAlertSeconds + nextAlertIntervalSeconds <=
        RestTimerSettings.maximumAlertSeconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '앱 설정',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              ListTile(
                title: const Text(
                  '초기 휴식 알림',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _formatRestTime(restTimerSettings.initialSeconds),
                  style: const TextStyle(color: Colors.black54),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const Key('decrease_initial_rest'),
                      tooltip: '초기 휴식 시간 줄이기',
                      icon: const Icon(Icons.remove, color: Colors.red),
                      onPressed:
                          restTimerSettings.initialSeconds >
                              RestTimerSettings.minimumInitialSeconds
                          ? () => _changeInitialSeconds(-10)
                          : null,
                    ),
                    IconButton(
                      key: const Key('increase_initial_rest'),
                      tooltip: '초기 휴식 시간 늘리기',
                      icon: const Icon(Icons.add, color: Colors.red),
                      onPressed:
                          restTimerSettings.initialSeconds <
                              RestTimerSettings.maximumInitialSeconds
                          ? () => _changeInitialSeconds(10)
                          : null,
                    ),
                  ],
                ),
              ),
              if (restTimerSettings.alertSeconds.isNotEmpty)
                const SizedBox(height: 8),
              ...restTimerSettings.alertSeconds.indexed.map((entry) {
                final index = entry.$1;
                final seconds = entry.$2;
                final previousSeconds = index == 0
                    ? restTimerSettings.initialSeconds
                    : restTimerSettings.alertSeconds[index - 1];
                final maximumSeconds = index + 1 <
                        restTimerSettings.alertSeconds.length
                    ? restTimerSettings.alertSeconds[index + 1] -
                          RestTimerSettings.minimumAlertGapSeconds
                    : RestTimerSettings.maximumAlertSeconds;
                final alertColor = Color.lerp(
                  Colors.red.shade50,
                  Colors.red.shade400,
                  ((index + 1) / 5).clamp(0.0, 1.0).toDouble(),
                )!;
                return Column(
                  children: [
                    Container(
                      key: Key('rest_alert_card_$index'),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: alertColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          '추가 알림 ${index + 1}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _formatRestTime(seconds),
                          style: const TextStyle(color: Colors.black54),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: Key('decrease_rest_alert_$index'),
                              tooltip: '알림 시간 줄이기',
                              icon: const Icon(Icons.remove, color: Colors.red),
                              onPressed: seconds >
                                      previousSeconds +
                                          RestTimerSettings.minimumAlertGapSeconds
                                  ? () => _changeAlertSeconds(index, -10)
                                  : null,
                            ),
                            IconButton(
                              key: Key('increase_rest_alert_$index'),
                              tooltip: '알림 시간 늘리기',
                              icon: const Icon(Icons.add, color: Colors.red),
                              onPressed: seconds < maximumSeconds
                                  ? () => _changeAlertSeconds(index, 10)
                                  : null,
                            ),
                            IconButton(
                              key: Key('remove_rest_alert_$index'),
                              tooltip: '알림 삭제',
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black54,
                              ),
                              onPressed: () => _removeAlert(index),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: OutlinedButton.icon(
                  key: const Key('add_rest_alert'),
                  onPressed: canAddAlert ? _addAlert : null,
                  icon: const Icon(Icons.add),
                  label: const Text('알림 시점 추가'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade800,
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: const ListTile(
            title: Text(
              '앱 정보',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'HMT v0.5.0',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }
}
