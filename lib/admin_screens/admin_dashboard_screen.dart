// lib/admin_screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:sams/services/api.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  bool   _isLoading = true;
  String _error     = '';

  Map<String, dynamic>       _overview    = {};
  List<Map<String, dynamic>> _byYear      = [];
  List<Map<String, dynamic>> _byDept      = [];
  List<Map<String, dynamic>> _courseStats = [];

  // ── Theme colour ───────────────────────────────────────────────────────────
  static const _navy = Color.fromARGB(255, 6, 34, 78);

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Load data from API ─────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final data = await ApiService.getDashboardStats();
      if (!mounted) return;
      setState(() {
        _overview    = Map<String, dynamic>.from(data['overview']              ?? {});
        _byYear      = List<Map<String, dynamic>>.from(data['students_by_year']       ?? []);
        _byDept      = List<Map<String, dynamic>>.from(data['students_by_department'] ?? []);
        _courseStats = List<Map<String, dynamic>>.from(data['course_stats']           ?? []);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  int    _ov(String key) => (_overview[key] as num?)?.toInt()    ?? 0;

  // ── Stat card widget ───────────────────────────────────────────────────────
  Widget _statCard({
    required String   label,
    required String   value,
    required IconData icon,
    Color?            iconColor,
    Color?            bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? _navy).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor ?? _navy, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold,
                  color: iconColor ?? _navy)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // ── Horizontal bar chart for year breakdown ────────────────────────────────
  Widget _yearBar(Map<String, dynamic> row, int maxCount) {
    final year  = row['year'] as int? ?? 0;
    final count = (row['count'] as num?)?.toInt() ?? 0;
    final frac  = maxCount > 0 ? count / maxCount : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text('Year $year',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value:           frac,
                minHeight:       22,
                backgroundColor: Colors.grey[200],
                valueColor:
                const AlwaysStoppedAnimation<Color>(_navy),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: Text('$count',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Pass-rate colour ───────────────────────────────────────────────────────
  Color _rateColor(double rate) {
    if (rate >= 75) return Colors.green;
    if (rate >= 50) return Colors.orange;
    return Colors.red;
  }

  // ── Section title ──────────────────────────────────────────────────────────
  Widget _sectionTitle(String text) => Padding(
    padding:
    const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(text,
        style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _navy)),
  );

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Analytics Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon:      const Icon(Icons.refresh),
            onPressed: _load,
            tooltip:   'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _load,
                child: const Text('Retry')),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Overview grid ──────────────────────────────────
              _sectionTitle('System Overview'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap:       true,
                physics:          const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing:  12,
                childAspectRatio: 1.35,
                children: [
                  _statCard(
                    label: 'Total Students',
                    value: '${_ov('total_students')}',
                    icon:  Icons.school_outlined,
                  ),
                  _statCard(
                    label: 'Total Advisors',
                    value: '${_ov('total_advisors')}',
                    icon:  Icons.medical_services_outlined,
                    iconColor: Colors.teal,
                  ),
                  _statCard(
                    label: 'Total Courses',
                    value: '${_ov('total_courses')}',
                    icon:  Icons.menu_book_outlined,
                    iconColor: Colors.indigo,
                  ),
                  _statCard(
                    label: 'Total Enrollments',
                    value: '${_ov('total_enrollments')}',
                    icon:  Icons.assignment_outlined,
                    iconColor: Colors.deepPurple,
                  ),
                  _statCard(
                    label: 'Pending Users',
                    value: '${_ov('pending_users')}',
                    icon:  Icons.person_add_outlined,
                    iconColor: Colors.orange,
                  ),
                  _statCard(
                    label: 'Pending Enrollments',
                    value: '${_ov('pending_enrollments')}',
                    icon:  Icons.pending_actions_outlined,
                    iconColor: Colors.amber[800],
                  ),
                ],
              ),

              // ── Enrollment status breakdown ────────────────────
              _sectionTitle('Enrollment Breakdown'),
              Container(
                padding:
                const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                        color:     Colors.black12,
                        blurRadius: 6,
                        offset:    Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    _enrollmentRow(
                      label: 'Approved Enrollments',
                      value: _ov('approved_enrollments'),
                      total: _ov('total_enrollments'),
                      color: _navy,
                    ),
                    const SizedBox(height: 14),
                    _enrollmentRow(
                      label: 'Passed',
                      value: _ov('passed_enrollments'),
                      total: _ov('approved_enrollments'),
                      color: Colors.green,
                    ),
                    const SizedBox(height: 14),
                    _enrollmentRow(
                      label: 'Failed',
                      value: _ov('failed_enrollments'),
                      total: _ov('approved_enrollments'),
                      color: Colors.red,
                    ),
                    const SizedBox(height: 14),
                    _enrollmentRow(
                      label: 'In Progress (Registered)',
                      value: _ov('registered_enrollments'),
                      total: _ov('approved_enrollments'),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),

              // ── Students by year ───────────────────────────────
              _sectionTitle('Students by Year Level'),
              Container(
                padding:
                const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                        color:     Colors.black12,
                        blurRadius: 6,
                        offset:    Offset(0, 3)),
                  ],
                ),
                child: _byYear.isEmpty
                    ? const Text('No data yet.',
                    style: TextStyle(
                        color: Colors.grey))
                    : Column(
                  children: () {
                    final maxC = _byYear
                        .map((r) =>
                    (r['count'] as num?)
                        ?.toInt() ??
                        0)
                        .fold(0, (a, b) =>
                    a > b ? a : b);
                    return _byYear
                        .map((r) =>
                        _yearBar(r, maxC))
                        .toList();
                  }(),
                ),
              ),

              // ── Students by department ─────────────────────────
              if (_byDept.isNotEmpty) ...[
                _sectionTitle('Students by Department'),
                Container(
                  decoration: BoxDecoration(
                    color:        Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                          color:     Colors.black12,
                          blurRadius: 6,
                          offset:    Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header row
                      _deptHeaderRow(),
                      ..._byDept.asMap().entries.map((entry) =>
                          _deptRow(entry.value,
                              entry.key % 2 == 1)),
                    ],
                  ),
                ),
              ],

              // ── Course statistics ──────────────────────────────
              if (_courseStats.isNotEmpty) ...[
                _sectionTitle('Course Statistics'),
                ..._courseStats.asMap().entries.map((entry) =>
                    _courseCard(entry.value)),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Enrollment breakdown row ───────────────────────────────────────────────
  Widget _enrollmentRow({
    required String label,
    required int    value,
    required int    total,
    required Color  color,
  }) {
    final fraction = (total > 0) ? (value / total).clamp(0.0, 1.0) : 0.0;
    final pct      = (fraction * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
            Text('$value  ($pct%)',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value:           fraction,
            minHeight:       10,
            backgroundColor: Colors.grey[200],
            valueColor:      AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ── Department table rows ──────────────────────────────────────────────────
  Widget _deptHeaderRow() {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color:        _navy,
        borderRadius: const BorderRadius.only(
          topLeft:  Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
              child: Text('Department',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13))),
          Text('Students',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _deptRow(Map<String, dynamic> row, bool isAlt) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isAlt ? Colors.grey[50] : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Text(
              row['department']?.toString() ?? '',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            '${row['count'] ?? 0}',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ── Course stat card ───────────────────────────────────────────────────────
  Widget _courseCard(Map<String, dynamic> course) {
    final name        = course['course_name']  as String? ?? '';
    final code        = course['course_code']  as String? ?? '';
    final dept        = course['department']   as String? ?? '';
    final level       = (course['level']       as num?)?.toInt() ?? 0;
    final capacity    = (course['capacity']    as num?)?.toInt() ?? 0;
    final enrolled    = (course['enrolled_count'] as num?)?.toInt() ?? 0;
    final passed      = (course['passed_count']   as num?)?.toInt() ?? 0;
    final failed      = (course['failed_count']   as num?)?.toInt() ?? 0;
    final registered  = (course['registered_count'] as num?)?.toInt() ?? 0;
    final passRate    = (course['pass_rate']      as num?)?.toDouble() ?? 0.0;
    final occupancy   = (course['occupancy_rate'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Course name + code ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _navy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(code,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _navy)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ── Meta row ──────────────────────────────────────────────────
            Wrap(
              spacing: 12,
              children: [
                if (dept.isNotEmpty)
                  _metaChip(dept, Colors.indigo),
                _metaChip('Year $level', Colors.teal),
                _metaChip('Cap: $capacity', Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Stats row ─────────────────────────────────────────────────
            Row(
              children: [
                _miniStat('Enrolled', '$enrolled', Colors.blue),
                const SizedBox(width: 12),
                _miniStat('Passed', '$passed', Colors.green),
                const SizedBox(width: 12),
                _miniStat('Failed', '$failed', Colors.red),
                const SizedBox(width: 12),
                _miniStat('Active', '$registered', Colors.orange),
              ],
            ),
            const SizedBox(height: 12),

            // ── Pass rate bar ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pass Rate',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('${passRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _rateColor(passRate))),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (passRate / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                    _rateColor(passRate)),
              ),
            ),
            const SizedBox(height: 10),

            // ── Occupancy bar ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Occupancy',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('${occupancy.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _navy)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (occupancy / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(_navy),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color)),
  );

  Widget _miniStat(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Colors.grey)),
        ],
      ),
    ),
  );
}