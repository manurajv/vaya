import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _currencyFormatDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _compactFormat = NumberFormat.compact(locale: 'en_IN');

  static String formatCurrency(double amount, {bool showDecimal = false}) {
    if (showDecimal) return _currencyFormatDecimal.format(amount);
    return _currencyFormat.format(amount);
  }

  static String formatCompactCurrency(double amount) {
    return '₹${_compactFormat.format(amount)}';
  }

  static String formatQuantity(int quantity, String unit) {
    if (quantity >= 1000) {
      return '${_compactFormat.format(quantity)} $unit';
    }
    return '$quantity $unit';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatCountdown(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) return 'Expired';

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  static String formatCountdownShort(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) return 'Expired';

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  static String formatPhoneNumber(String phone) {
    if (phone.length == 10) {
      return '+91 ${phone.substring(0, 5)} ${phone.substring(5)}';
    }
    return phone;
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String formatAudioDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String formatOrderId(String id) {
    if (id.length > 8) return '#${id.substring(0, 8).toUpperCase()}';
    return '#${id.toUpperCase()}';
  }

  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  static String formatDiscount(double original, double discounted) {
    if (original <= 0) return '';
    final discount = ((original - discounted) / original) * 100;
    return '${discount.toStringAsFixed(0)}% OFF';
  }
}
