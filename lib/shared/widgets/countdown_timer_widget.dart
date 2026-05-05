import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';

class CountdownTimerWidget extends StatefulWidget {
  final DateTime deadline;
  final TextStyle? style;
  final bool showIcon;
  final bool compact;
  final VoidCallback? onExpired;

  const CountdownTimerWidget({
    super.key,
    required this.deadline,
    this.style,
    this.showIcon = true,
    this.compact = false,
    this.onExpired,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late Timer _timer;
  late Duration _remaining;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    if (now.isAfter(widget.deadline)) {
      if (!_expired) {
        setState(() {
          _remaining = Duration.zero;
          _expired = true;
        });
        widget.onExpired?.call();
      }
      return;
    }
    setState(() {
      _remaining = widget.deadline.difference(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Color get _timerColor {
    if (_expired) return AppColors.error;
    if (_remaining.inHours < 2) return AppColors.error;
    if (_remaining.inHours < 12) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.compact
        ? Formatters.formatCountdownShort(_remaining)
        : Formatters.formatCountdown(_remaining);

    final style = widget.style ??
        TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _timerColor,
        );

    if (widget.showIcon) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _expired ? Icons.timer_off_outlined : Icons.timer_outlined,
            size: 14,
            color: _timerColor,
          ),
          const SizedBox(width: 4),
          Text(text, style: style),
        ],
      );
    }

    return Text(text, style: style);
  }
}

/// A more visual countdown widget with boxes for days/hours/minutes/seconds
class CountdownBoxWidget extends StatefulWidget {
  final DateTime deadline;
  final VoidCallback? onExpired;

  const CountdownBoxWidget({
    super.key,
    required this.deadline,
    this.onExpired,
  });

  @override
  State<CountdownBoxWidget> createState() => _CountdownBoxWidgetState();
}

class _CountdownBoxWidgetState extends State<CountdownBoxWidget> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    if (now.isAfter(widget.deadline)) {
      setState(() => _remaining = Duration.zero);
      widget.onExpired?.call();
      _timer.cancel();
      return;
    }
    setState(() => _remaining = widget.deadline.difference(now));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (days > 0) ...[
          _TimeBox(value: days, label: 'Days'),
          _Separator(),
        ],
        _TimeBox(value: hours, label: 'Hrs'),
        _Separator(),
        _TimeBox(value: minutes, label: 'Min'),
        _Separator(),
        _TimeBox(value: seconds, label: 'Sec'),
      ],
    );
  }
}

class _TimeBox extends StatelessWidget {
  final int value;
  final String label;

  const _TimeBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
