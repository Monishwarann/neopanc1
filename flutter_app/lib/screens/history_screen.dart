import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/datetime_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_primary_button.dart';
import 'main_wrapper.dart';
import 'report_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _historyLogs = [];
  bool _isLoading = true;
  String _filter = 'All';
  String _searchQuery = '';
  String _timePeriodFilter = 'All Time';
  String _sortBy = 'Newest First';
  
  StreamSubscription<List<Map<String, dynamic>>>? _historySub;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _subscribeToHistory();
  }

  void _subscribeToHistory() {
    final provider = Provider.of<UserStateProvider>(context, listen: false);
    final userId = provider.userId ?? '1';
    
    _historySub?.cancel();
    _historySub = _firebaseService.streamHistoryLogs(userId).listen((logs) {
      if (mounted) {
        setState(() {
          _historyLogs = logs;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print("Error listening to history logs: $error");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _historySub?.cancel();
    super.dispose();
  }

  void _downloadPdf(Map<String, dynamic> log) async {
    final provider = Provider.of<UserStateProvider>(context, listen: false);
    final api = ApiService(baseUrl: provider.baseUrl);
    final logId = log['id']?.toString() ?? log['log_id']?.toString() ?? 'new';
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading PDF Report...'), duration: Duration(seconds: 1)),
    );
    
    final file = await api.downloadPdf(logId, logData: log);
    if (file != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report downloaded successfully.'), backgroundColor: Colors.green));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download PDF', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

  void _shareReport(Map<String, dynamic> log) async {
    final provider = Provider.of<UserStateProvider>(context, listen: false);
    final api = ApiService(baseUrl: provider.baseUrl);
    final logId = log['id']?.toString() ?? log['log_id']?.toString() ?? 'new';
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing report to share...'), duration: Duration(seconds: 1)),
      );
    }
    
    final pcriScore = log['pcri_score']?.toString() ?? '0.0';
    final riskLevel = log['risk_level']?.toString() ?? 'Low';
    final url = log['pdfUrl'] ?? log['pdf_download_url'] ?? '';
    
    final shareText = 'My Pancreatic Cancer Risk Assessment Report.\nRisk Level: $riskLevel Risk (Score: $pcriScore%)\n${url.isNotEmpty ? "View Report: $url" : ""}';

    if (kIsWeb) {
      try {
        await Share.share(
          shareText,
          subject: 'Pancreatic Cancer Risk Assessment Report',
        );
      } catch (e) {
        print("Web share failed: $e");
        // Fallback for clipboard
        if (url.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: url));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report URL copied to clipboard!'), backgroundColor: Colors.green),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sharing failed: cloud URL not ready.'), backgroundColor: Colors.redAccent),
            );
          }
        }
      }
    } else {
      try {
        final bytes = await api.fetchPdfBytes(logId, logData: log);
        if (bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to prepare PDF report bytes.'), backgroundColor: Colors.redAccent),
            );
          }
          return;
        }
        
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/report_$logId.pdf');
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          text: shareText,
          subject: 'Pancreatic Cancer Risk Assessment Report',
        );
      } catch (e) {
        print("Error native sharing PDF: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sharing report: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  void _deleteReport(Map<String, dynamic> log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Report?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will permanently delete the report Firestore log and the cloud PDF document. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white30)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<UserStateProvider>(context, listen: false);
      final userId = provider.userId ?? '1';
      final logId = log['id'] ?? log['log_id'] ?? 'new';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting report from cloud storage...')),
      );

      await _firebaseService.deletePredictionLog(userId, logId);
      await _firebaseService.deleteMedicalReport(userId, logId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted successfully.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    
    final filteredLogs = _historyLogs.where((log) {
      // 1. Risk Level Filter
      if (_filter != 'All' && log['risk_level'] != _filter) return false;

      final date = DateTimeService.parseToLocal(log['timestamp'] ?? log['createdAt']);

      // 2. Time Period Filter
      if (_timePeriodFilter != 'All Time') {
        final difference = now.difference(date);
        if (_timePeriodFilter == 'Today') {
          final isSameDay = date.day == now.day && date.month == now.month && date.year == now.year;
          if (!isSameDay) return false;
        } else if (_timePeriodFilter == 'Yesterday') {
          final yesterday = now.subtract(const Duration(days: 1));
          final isYesterday = date.day == yesterday.day && date.month == yesterday.month && date.year == yesterday.year;
          if (!isYesterday) return false;
        } else if (_timePeriodFilter == 'Last 7 Days') {
          if (difference.inDays > 7) return false;
        } else if (_timePeriodFilter == 'Last 30 Days') {
          if (difference.inDays > 30) return false;
        } else if (_timePeriodFilter == 'This Month') {
          if (date.month != now.month || date.year != now.year) return false;
        } else if (_timePeriodFilter == 'This Year') {
          if (date.year != now.year) return false;
        }
      }

      // 3. Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final name = (log['patient_name'] ?? 'Patient').toString().toLowerCase();
        final formattedDate = DateTimeService.formatDate(date).toLowerCase();
        final formattedTime = DateTimeService.formatTime(date).toLowerCase();
        final formattedTimeSec = DateTimeService.formatTimeWithSeconds(date).toLowerCase();
        final logId = (log['id'] ?? log['log_id'] ?? '').toString().toLowerCase();
        final risk = (log['risk_level'] ?? '').toString().toLowerCase();
        final score = (log['pcri_score'] ?? '').toString().toLowerCase();

        final matchesName = name.contains(query);
        final matchesDate = formattedDate.contains(query);
        final matchesTime = formattedTime.contains(query) || formattedTimeSec.contains(query);
        final matchesId = logId.contains(query);
        final matchesRisk = risk.contains(query);
        final matchesScore = score.contains(query);

        if (!matchesName && !matchesDate && !matchesTime && !matchesId && !matchesRisk && !matchesScore) return false;
      }

      return true;
    }).toList();

    // 4. Advanced Sorting
    filteredLogs.sort((a, b) {
      final dateA = DateTimeService.parseToLocal(a['timestamp'] ?? a['createdAt']);
      final dateB = DateTimeService.parseToLocal(b['timestamp'] ?? b['createdAt']);
      
      if (_sortBy == 'Newest First' || _sortBy == 'Latest Prediction') {
        return dateB.compareTo(dateA);
      } else if (_sortBy == 'Oldest First') {
        return dateA.compareTo(dateB);
      } else if (_sortBy == 'Highest Risk') {
        int getRank(String? level) {
          if (level == 'High') return 3;
          if (level == 'Moderate') return 2;
          return 1;
        }
        final rankCompare = getRank(b['risk_level']).compareTo(getRank(a['risk_level']));
        if (rankCompare != 0) return rankCompare;
        return dateB.compareTo(dateA);
      } else if (_sortBy == 'Lowest Risk') {
        int getRank(String? level) {
          if (level == 'High') return 3;
          if (level == 'Moderate') return 2;
          return 1;
        }
        final rankCompare = getRank(a['risk_level']).compareTo(getRank(b['risk_level']));
        if (rankCompare != 0) return rankCompare;
        return dateB.compareTo(dateA);
      } else if (_sortBy == 'Highest Confidence') {
        final confA = double.tryParse(a['ai_confidence']?.toString() ?? '0') ?? 0.0;
        final confB = double.tryParse(b['ai_confidence']?.toString() ?? '0') ?? 0.0;
        final confCompare = confB.compareTo(confA);
        if (confCompare != 0) return confCompare;
        return dateB.compareTo(dateA);
      } else if (_sortBy == 'Lowest Confidence') {
        final confA = double.tryParse(a['ai_confidence']?.toString() ?? '0') ?? 0.0;
        final confB = double.tryParse(b['ai_confidence']?.toString() ?? '0') ?? 0.0;
        final confCompare = confA.compareTo(confB);
        if (confCompare != 0) return confCompare;
        return dateB.compareTo(dateA);
      }
      return 0;
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/6.jpeg',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Timeline History'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : Column(
              children: [
                // Filter Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Low', 'Moderate', 'High'].map((filter) {
                        final isSelected = _filter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) setState(() => _filter = filter);
                            },
                            selectedColor: theme.primaryColor.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withOpacity(0.1)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Search Bar and Sorting Dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
                          ),
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: TextStyle(color: theme.colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Search by date, time, ID...',
                              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                              prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Date period and sorting criteria selectors
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _timePeriodFilter,
                              dropdownColor: theme.colorScheme.surface,
                              icon: Icon(Icons.calendar_today, size: 14, color: theme.primaryColor),
                              style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
                              onChanged: (val) {
                                if (val != null) setState(() => _timePeriodFilter = val);
                              },
                              items: ['All Time', 'Today', 'Yesterday', 'Last 7 Days', 'Last 30 Days', 'This Month', 'This Year']
                                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _sortBy,
                              dropdownColor: theme.colorScheme.surface,
                              icon: Icon(Icons.sort, size: 14, color: theme.primaryColor),
                              style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
                              onChanged: (val) {
                                if (val != null) setState(() => _sortBy = val);
                              },
                              items: ['Newest First', 'Oldest First', 'Highest Risk', 'Lowest Risk', 'Highest Confidence', 'Lowest Confidence', 'Latest Prediction']
                                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Timeline List
                Expanded(
                  child: filteredLogs.isEmpty
                      ? _buildEmptyState(theme)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = filteredLogs[index];
                            final isLast = index == filteredLogs.length - 1;
                            return _buildTimelineItem(log, isLast, theme);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_toggle_off, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            ),
            const SizedBox(height: 24),
            Text(
              'No Medical Reports Found',
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first AI screening to automatically generate a secure cloud report.',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AnimatedPrimaryButton(
              text: 'Start New Prediction',
              icon: Icons.add,
              onPressed: () {
                MainWrapper.switchTab(context, 1);
                Navigator.pop(context); // Close History panel back to tab controller
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(dynamic log, bool isLast, ThemeData theme) {
    final date = DateTimeService.parseToLocal(log['timestamp'] ?? log['createdAt']);
    final predictionDate = DateTimeService.formatDate(date);
    final predictionTime = DateTimeService.formatTimeWithSeconds(date);
    final relativeTime = DateTimeService.formatRelativeTime(date);
    
    final riskLevel = log['risk_level'] ?? 'Low';
    Color riskColor = Colors.green;
    IconData riskIcon = Icons.check_circle_rounded;
    if (riskLevel == 'Moderate') {
      riskColor = Colors.orange;
      riskIcon = Icons.warning_rounded;
    } else if (riskLevel == 'High') {
      riskColor = Colors.redAccent;
      riskIcon = Icons.error_rounded;
    }

    final pdfUrl = log['pdfUrl'] ?? log['pdf_download_url'] ?? '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line and dot
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: riskColor.withOpacity(0.2),
                  border: Border.all(color: riskColor, width: 3),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: GlassCard(
                padding: const EdgeInsets.all(20.0),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(relativeTime, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.onSurface)),
                            const SizedBox(height: 4),
                            Text('Report: #${log['id'] ?? log['log_id'] ?? 'N/A'}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(riskIcon, size: 14, color: riskColor),
                              const SizedBox(width: 4),
                              Text(
                                riskLevel.toUpperCase(),
                                style: TextStyle(color: riskColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Patient: ${log['patient_name'] ?? 'Patient Name'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'AI Confidence: ${log['ai_confidence'] ?? 0.0}%',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PCRI Score', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 11)),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${log['pcri_score']}',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
                                ),
                                Text(' / 100', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                              ],
                            ),
                          ],
                        ),
                        
                        // Action Buttons Bar
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.white70),
                              tooltip: 'View Report',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ReportDetailsScreen(log: log)),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.download, size: 20, color: Colors.white70),
                              tooltip: 'Download PDF',
                              onPressed: () => _downloadPdf(log),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_outlined, size: 20, color: Colors.white70),
                              tooltip: 'Share Report',
                              onPressed: () => _shareReport(log),
                            ),
                            if (pdfUrl.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.cloud_queue, size: 20, color: Colors.blueAccent),
                                tooltip: 'Open Cloud Copy',
                                onPressed: () => _downloadPdf(log), // opens locally / cloud copy
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              tooltip: 'Delete Report',
                              onPressed: () => _deleteReport(log),
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
