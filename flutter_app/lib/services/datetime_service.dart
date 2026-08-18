import 'package:intl/intl.dart';

class DateTimeService {
  // Consistent format constants
  static const String dateFormatPattern = 'd MMMM yyyy'; // e.g., 30 June 2026
  static const String dateCompactPattern = 'dd/MM/yyyy'; // e.g., 30/06/2026
  static const String timeFormatPattern = 'hh:mm a'; // e.g., 11:02 PM
  static const String timeWithSecondsPattern = 'hh:mm:ss a'; // e.g., 11:02:56 PM

  // Detect and return local timezone name/offset
  static String get localTimezone {
    final now = DateTime.now();
    return now.timeZoneName;
  }

  static String get localTimezoneOffset {
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours.toString().padLeft(2, '0');
    final minutes = (offset.inMinutes % 60).abs().toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';
    return '$sign$hours:$minutes';
  }

  // Parse ISO string or DateTime, converting UTC to local
  static DateTime parseToLocal(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp.toLocal();
    
    String tsStr = timestamp.toString().trim();
    if (tsStr.isEmpty) return DateTime.now();

    // Standardize UTC ISO formatting for parser safety
    if (!tsStr.endsWith('Z') && 
        (tsStr.length <= 10 || (!tsStr.substring(10).contains('+') && !tsStr.substring(10).contains('-')))) {
      tsStr += 'Z';
    }
    
    try {
      return DateTime.parse(tsStr).toLocal();
    } catch (e) {
      print('DateTimeService error parsing "$timestamp": $e');
      return DateTime.now();
    }
  }

  // Format Date (e.g., "30 June 2026")
  static String formatDate(dynamic timestamp) {
    final date = parseToLocal(timestamp);
    return DateFormat(dateFormatPattern).format(date);
  }

  // Format Date Compact (e.g., "30/06/2026")
  static String formatDateCompact(dynamic timestamp) {
    final date = parseToLocal(timestamp);
    return DateFormat(dateCompactPattern).format(date);
  }

  // Format Time (e.g., "11:02 PM")
  static String formatTime(dynamic timestamp) {
    final date = parseToLocal(timestamp);
    return DateFormat(timeFormatPattern).format(date);
  }

  // Format Time with Seconds (e.g., "11:02:56 PM")
  static String formatTimeWithSeconds(dynamic timestamp) {
    final date = parseToLocal(timestamp);
    return DateFormat(timeWithSecondsPattern).format(date);
  }

  // Format Relative Time (e.g., "Today • 11:15 PM")
  static String formatRelativeTime(dynamic timestamp) {
    final date = parseToLocal(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    final isSameDay = date.day == now.day && date.month == now.month && date.year == now.year;
    
    // Yesterday check
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = date.day == yesterday.day && date.month == yesterday.month && date.year == yesterday.year;

    final formattedTime = formatTime(date);

    if (isSameDay) {
      return 'Today • $formattedTime';
    } else if (isYesterday) {
      return 'Yesterday • $formattedTime';
    } else if (difference.inDays < 7) {
      final days = difference.inDays == 0 ? 1 : difference.inDays;
      return '$days ${days == 1 ? "Day" : "Days"} Ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? "Week" : "Weeks"} Ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "Month" : "Months"} Ago';
    } else {
      return formatDate(date);
    }
  }
}
