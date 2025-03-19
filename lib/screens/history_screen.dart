import 'package:flutter/material.dart';
import 'package:attendance/services/mongodb_service.dart';
import 'package:intl/intl.dart';

enum FilterOption { all, today, thisWeek, thisMonth }

class HistoryScreen extends StatefulWidget {
  final MongoDBService mongoDBService;

  const HistoryScreen({super.key, required this.mongoDBService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allHistoryItems = [];
  List<Map<String, dynamic>> _filteredHistoryItems = [];
  final TextEditingController _searchController = TextEditingController();
  FilterOption _currentFilter = FilterOption.all;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      // Fetch only from local storage (via your MongoDB service method)
      final history = await widget.mongoDBService.getAttendanceHistory();
      setState(() => _allHistoryItems = history);
    } catch (e) {
      setState(() => _allHistoryItems = []);
    } finally {
      _applyFilters();
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final searchQuery = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> temp = List.from(_allHistoryItems);
    temp = _filterByDate(temp, _currentFilter);
    if (searchQuery.isNotEmpty) {
      temp = temp.where((item) {
        final regNo = (item['registrationNo'] as String? ?? '').toLowerCase();
        final name = (item['name'] as String? ?? '').toLowerCase();
        return regNo.contains(searchQuery) || name.contains(searchQuery);
      }).toList();
    }
    setState(() => _filteredHistoryItems = temp);
  }

  List<Map<String, dynamic>> _filterByDate(
      List<Map<String, dynamic>> items, FilterOption filter) {
    if (filter == FilterOption.all) return items;
    final now = DateTime.now();
    late DateTime startDate;
    if (filter == FilterOption.today) {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (filter == FilterOption.thisWeek) {
      startDate = DateTime(now.year, now.month, now.day - now.weekday + 1);
    } else if (filter == FilterOption.thisMonth) {
      startDate = DateTime(now.year, now.month, 1);
    }
    return items.where((item) {
      final timestamp = item['timestamp'] as DateTime;
      return timestamp.isAfter(startDate);
    }).toList();
  }

  void _setFilter(FilterOption filter) {
    setState(() => _currentFilter = filter);
    _applyFilters();
  }

  String _getFilterLabel(FilterOption filter) {
    switch (filter) {
      case FilterOption.today:
        return 'Today';
      case FilterOption.thisWeek:
        return 'This Week';
      case FilterOption.thisMonth:
        return 'This Month';
      default:
        return 'All Time';
    }
  }

  void _onTapRecord(Map<String, dynamic> record) {
    final bool marked = record['success'] as bool? ?? false;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Attendance Status"),
        content: Text(marked
            ? "User marked present for event: ${record['eventName']}"
            : "User not marked present for event: ${record['eventName']}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'No attendance history';
    if (_searchController.text.isNotEmpty) {
      message = 'No results found';
    } else if (_currentFilter == FilterOption.today) {
      message = 'No attendance today';
    } else if (_currentFilter == FilterOption.thisWeek) {
      message = 'No attendance this week';
    } else if (_currentFilter == FilterOption.thisMonth) {
      message = 'No attendance this month';
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredHistoryItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _filteredHistoryItems[index];
        final DateTime timestamp = item['timestamp'] as DateTime;
        final String formattedDate = _dateFormat.format(timestamp);
        final String regNo = (item['registrationNo'] as String?) ?? 'N/A';
        final String eventName =
            (item['eventName'] as String?) ?? 'Unknown Event';
        return InkWell(
          onTap: () => _onTapRecord(item),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.lightGreen.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person_outline,
                            color: Colors.lightGreen, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          regNo,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Event: $eventName',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.lightGreen,
        elevation: 0,
        actions: [
          PopupMenuButton<FilterOption>(
            icon: const Icon(Icons.filter_alt_outlined),
            onSelected: _setFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: FilterOption.all, child: Text('All Time')),
              const PopupMenuItem(
                  value: FilterOption.today, child: Text('Today')),
              const PopupMenuItem(
                  value: FilterOption.thisWeek, child: Text('This Week')),
              const PopupMenuItem(
                  value: FilterOption.thisMonth, child: Text('This Month')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or ID',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => _searchController.clear())
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_currentFilter != FilterOption.all ||
              _filteredHistoryItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  if (_currentFilter != FilterOption.all)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.lightGreen.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getFilterLabel(_currentFilter),
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.lightGreen.shade700),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _setFilter(FilterOption.all),
                            child: Icon(Icons.close,
                                size: 12, color: Colors.lightGreen.shade700),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Text('${_filteredHistoryItems.length} records',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.lightGreen))
                : _filteredHistoryItems.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(),
          ),
        ],
      ),
    );
  }
}
