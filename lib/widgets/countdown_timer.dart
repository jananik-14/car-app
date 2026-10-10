import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? style;
  final TextStyle? endingSoonStyle;
  final VoidCallback? onEnd;

  const CountdownTimer({
    super.key,
    required this.endTime,
    this.style,
    this.endingSoonStyle,
    this.onEnd,
  });

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  late Duration _timeLeft;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    if (widget.endTime.isBefore(now)) {
      if (!_ended) {
        _ended = true;
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _timeLeft = Duration.zero;
          });
          widget.onEnd?.call();
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _timeLeft = widget.endTime.difference(now);
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ended) {
      return Text('Ended', style: widget.style?.copyWith(color: Colors.red));
    }

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24);
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    String timeString = '';
    if (days > 0) timeString += '${days}d ';
    if (hours > 0 || days > 0) timeString += '${hours}h ';
    timeString += '${minutes}m ${seconds}s';

    final isEndingSoon = _timeLeft.inHours < 1;
    final textStyle = isEndingSoon 
        ? (widget.endingSoonStyle ?? widget.style?.copyWith(color: Colors.red)) 
        : widget.style;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time, size: 12, color: textStyle?.color ?? Colors.black),
        const SizedBox(width: 4),
        Text(timeString, style: textStyle),
        if (isEndingSoon) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Ending soon', style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ]
      ],
    );
  }
}
