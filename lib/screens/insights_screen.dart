import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/background_wrapper.dart';
import '../services/breathing_storage_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';


class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int? _selectedMoodPoint; // 0 for peak 1, 1 for peak 2
  bool _loadingInsights = true;
  String _dateRange = '';
  String _userName = 'You';
  Map<String, String> _summaryStats = {};
  List<double> _dailyMinutes = [];
  List<String> _weekDays = [];
  List<Map<String, String>> _keyInsights = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadInsights();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BackgroundWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dateRange.isNotEmpty ? _dateRange : '—',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Weekly Insights',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    _buildHeaderAction(Icons.calendar_month_rounded),
                  ],
                ),
                const SizedBox(height: 24),

                // Health Summary Card (Deep Glassmorphic)
                _buildGlassSummaryCard().animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // Mood Stability Area Chart
                _buildSectionTitle('Mood Stability'),
                const SizedBox(height: 16),
                _buildGlassChartContainer(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Emotional Flow',
                              style: GoogleFonts.outfit(
                                  fontSize: 14, color: AppTheme.textLight, fontWeight: FontWeight.w300)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('+15% Calm',
                                style: GoogleFonts.outfit(
                                    fontSize: 12, color: Colors.green, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTapDown: (details) {
                          HapticFeedback.lightImpact();
                          final localPos = details.localPosition;
                          final w = MediaQuery.of(context).size.width;
                          if (_dailyMinutes.isNotEmpty) {
                            final idxNum = ((localPos.dx / w) * (_dailyMinutes.length - 1)).round().clamp(0, _dailyMinutes.length - 1);
                            final idx = idxNum.toInt();
                            setState(() => _selectedMoodPoint = idx);
                          } else {
                            setState(() => _selectedMoodPoint = null);
                          }
                        },
                        child: Stack(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.22,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: _SophisticatedAreaChartPainter(
                                  selectedPoint: _selectedMoodPoint,
                                  data: _dailyMinutes,
                                ),
                              ),
                            ),
                            if (_selectedMoodPoint != null)
                              Builder(builder: (ctx) {
                                final w = MediaQuery.of(ctx).size.width;
                                final idx = _selectedMoodPoint!.clamp(0, (_dailyMinutes.isNotEmpty ? _dailyMinutes.length - 1 : 0)).toInt();
                                final left = _dailyMinutes.isNotEmpty && _dailyMinutes.length > 1
                                    ? (idx / (_dailyMinutes.length - 1)) * w
                                    : w * 0.5;
                                final valueText = (_dailyMinutes.isNotEmpty && idx < _dailyMinutes.length)
                                    ? '${_dailyMinutes[idx].toInt()}m'
                                    : '—';
                                return Positioned(
                                  top: 18,
                                  left: (left - 48).clamp(8.0, w - 120.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                                      ],
                                      border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      'Mood: $valueText',
                                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryTeal),
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: (_weekDays.isNotEmpty ? _weekDays : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                            .map((day) => Expanded(
                                  child: Center(
                                    child: Text(day,
                                        style: GoogleFonts.outfit(
                                            fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ).animate(delay: 300.ms).fadeIn(duration: 800.ms).scaleXY(begin: 0.95),

                const SizedBox(height: 24),

                // Mindful Minutes Bar Chart
                _buildSectionTitle('Mindful Minutes'),
                const SizedBox(height: 16),
                _buildGlassChartContainer(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Daily Usage',
                              style: GoogleFonts.outfit(
                                  fontSize: 14, color: AppTheme.textLight, fontWeight: FontWeight.w300)),
                          Text(
                            _dailyMinutes.isNotEmpty
                                    ? '${_dailyMinutes.map((d) => d.toInt()).reduce((a, b) => a + b)}m Total'
                                : '—',
                            style: GoogleFonts.outfit(
                                fontSize: 14, color: AppTheme.primaryTeal, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_dailyMinutes.isEmpty)
                        Center(child: Text('No usage data yet', style: GoogleFonts.outfit(color: AppTheme.textLight)))
                      else
                        SizedBox(
                          height: 160,
                          child: LayoutBuilder(builder: (context, constraints) {
                                final maxVal = _dailyMinutes.isNotEmpty ? _dailyMinutes.reduce((a, b) => a > b ? a : b) : 0.0;
                            final barMaxHeight = constraints.maxHeight > 0 ? constraints.maxHeight * 0.6 : 120.0;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(_dailyMinutes.length, (i) {
                                final val = _dailyMinutes[i];
                                final factor = maxVal > 0 ? (val / maxVal) : 0.0;
                                final label = i < _weekDays.length ? _weekDays[i].substring(0, 1) : ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i];
                                return _buildAnimatedBar(factor, label, maxBarHeight: barMaxHeight, isPulsing: i == _dailyMinutes.length - 1)
                                    .animate(delay: (i * 100).ms)
                                    .fadeIn()
                                    .slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack);
                              }),
                            );
                          }),
                        ),
                    ],
                  ),
                ).animate(delay: 300.ms).fadeIn(duration: 800.ms).scaleXY(begin: 0.95),

                const SizedBox(height: 24),

                // Key Insights Section
                _buildSectionTitle('Key Observations'),
                const SizedBox(height: 16),
                if (_keyInsights.isEmpty)
                  Center(child: Text('No insights available yet', style: GoogleFonts.outfit(color: AppTheme.textLight)))
                else
                      ..._keyInsights.map((ins) {
                        final iconCode = int.tryParse(ins['icon'] ?? '') ?? Icons.help.codePoint;
                        final col = int.tryParse(ins['color'] ?? '') ?? AppTheme.primaryTeal.value;
                        return _buildInsightTile(
                            icon: IconData(iconCode, fontFamily: 'MaterialIcons'),
                            color: Color(col),
                            title: ins['title'] ?? 'Insight',
                            desc: ins['desc'] ?? '');
                      }).toList(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadInsights() async {
    // Default: load last 7 days ending today
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final end = DateTime(now.year, now.month, now.day);
    await _loadInsightsForRange(start, end);
  }

  /// Show a date range picker and reload insights for the chosen range.
  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final defaultStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final defaultEnd = DateTime(now.year, now.month, now.day);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(start: defaultStart, end: defaultEnd),
    );

    if (picked == null) return; // cancelled

    await _loadInsightsForRange(picked.start, picked.end);
  }

  /// Load insights for an arbitrary [start]..[end] date range (inclusive).
  Future<void> _loadInsightsForRange(DateTime start, DateTime end) async {
    setState(() {
      _loadingInsights = true;
    });

    final svc = BreathingStorageService();
    // small delay to simulate real fetch latency
    await Future.delayed(const Duration(milliseconds: 150));

    // Format date range for header
    final fmt = DateFormat.MMMd();
    _dateRange = '${fmt.format(start)} - ${fmt.format(end)}';

    // Basic static user/summary data
    _userName = 'You';
    _summaryStats = {'sleep': '—', 'heart': '—', 'steps': '—'};

    try {
      final sessions = await svc.getAllSessions();

      // prepare keys for each day in range
      final daysCount = end.difference(start).inDays + 1;
      final days = List<DateTime>.generate(daysCount, (i) => DateTime(start.year, start.month, start.day).add(Duration(days: i)));

      // accumulate seconds per dayKey
      final Map<String, int> totals = {};
      for (final s in sessions) {
        final ts = DateTime.fromMillisecondsSinceEpoch(s['ts']!);
        final dayKey = '${ts.year}-${ts.month}-${ts.day}';
        if (!ts.isBefore(start) && !ts.isAfter(end)) {
          totals[dayKey] = (totals[dayKey] ?? 0) + (s['duration'] ?? 0);
        }
      }

      // build minutes list aligned with days[]
      final List<double> minutes = [];
      for (final d in days) {
        final key = '${d.year}-${d.month}-${d.day}';
        final secs = totals[key] ?? 0;
        minutes.add(secs / 60.0);
      }

      _dailyMinutes = minutes;
      // weekday short names for labels
      _weekDays = days.map((d) => DateFormat.E().format(d)).toList();

      // key insights: simple heuristics with guards
      _keyInsights = [];
      if (_dailyMinutes.isNotEmpty) {
        final avg = _dailyMinutes.isNotEmpty ? (_dailyMinutes.reduce((a, b) => a + b) / _dailyMinutes.length) : 0.0;
        final lastMin = _dailyMinutes.last;
        if (lastMin >= avg && lastMin > 0) {
          _keyInsights.add({
            'icon': Icons.emoji_emotions_outlined.codePoint.toString(),
            'color': Colors.green.value.toString(),
            'title': 'Great Today',
            'desc': 'You spent ${lastMin.toInt()}m today — above period average.',
          });
        } else if (lastMin > 0) {
          _keyInsights.add({
            'icon': Icons.access_time_filled.codePoint.toString(),
            'color': Colors.orange.value.toString(),
            'title': 'Keep Going',
            'desc': 'Today: ${lastMin.toInt()}m — try a short session to boost your streak.',
          });
        }
      }
    } catch (e) {
      _dailyMinutes = [];
      _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      _keyInsights = [];
    }

    setState(() => _loadingInsights = false);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: AppTheme.textDark,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon) {
    return GestureDetector(
      onTap: _pickDateRange,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppTheme.primaryTeal.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: AppTheme.primaryTeal, size: 22),
      ),
    );
  }

  Widget _buildGlassSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryTeal.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.7),
                  Colors.white.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                          child: Icon(Icons.person_outline_rounded, color: Colors.white, size: 20)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${_userName}'s Dashboard",
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                              letterSpacing: -0.5),
                        ),
                        Text(
                          "Personal Health Summary",
                          style: GoogleFonts.outfit(
                              fontSize: 12, fontWeight: FontWeight.w300, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryStat(_summaryStats['sleep'] ?? '—', 'Sleep Avg', Icons.nightlight_round_rounded, Colors.indigoAccent),
                    _buildSummaryStat(_summaryStats['heart'] ?? '—', 'Avg Heart', Icons.favorite_rounded, AppTheme.primaryTeal),
                    _buildSummaryStat(_summaryStats['steps'] ?? '—', 'Steps Count', Icons.directions_walk_rounded, Colors.orangeAccent),
                  ],
                ),
                const SizedBox(height: 12),
                // Average mindful minutes indicator
                Builder(builder: (ctx) {
                  final avg = _dailyMinutes.isNotEmpty ? (_dailyMinutes.reduce((a, b) => a + b) / _dailyMinutes.length) : 0.0;
                  const target = 60.0;
                  final pct = (avg / target).clamp(0.0, 1.0);
                  return Row(
                    children: [
                      SizedBox(
                        width: 68,
                        height: 68,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: pct,
                              strokeWidth: 6,
                               valueColor: AlwaysStoppedAnimation(AppTheme.primaryTeal),
                               backgroundColor: AppTheme.primaryTeal.withOpacity(0.12),
                            ),
                            Text(
                              '${avg.toInt()}m',
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Avg mindfulness minutes/day — ${pct >= 1.0 ? 'On target' : 'Keep going'}',
                          style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String val, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(val,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
        Text(label,
            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w300)),
      ],
    );
  }

  Widget _buildGlassChartContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryTeal.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.7),
                  Colors.white.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBar(double heightFactor, String label, {bool isPulsing = false, double? maxBarHeight}) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = isPulsing ? 1.0 + (_pulseController.value * 0.1) : 1.0;
            return Transform.scale(
              scaleX: scale,
              scaleY: scale,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 16,
                height: (() {
                  final base = maxBarHeight ?? (MediaQuery.of(context).size.height * 0.18);
                  final raw = heightFactor * base;
                  final upper = MediaQuery.of(context).size.height * 0.5;
                  return raw.clamp(8.0, upper);
                })(),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryTeal, AppTheme.primaryTeal.withOpacity(0.4)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                      BoxShadow(
                      color: AppTheme.primaryTeal
                          .withOpacity(isPulsing ? 0.3 * _pulseController.value : 0.1),
                      blurRadius: isPulsing ? 15 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(label,
            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildInsightTile(
      {required IconData icon, required Color color, required String title, required String desc}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                            letterSpacing: -0.2)),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textLight,
                        height: 1.6,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SophisticatedAreaChartPainter extends CustomPainter {
  final int? selectedPoint;
  final List<double>? data;
  _SophisticatedAreaChartPainter({this.selectedPoint, this.data});

  @override
  void paint(Canvas canvas, Size size) {
    // If we have data, draw area chart based on data; otherwise fallback to decorative path.
    if (data == null || data!.isEmpty) {
      // fallback decorative path
      final shadowPaint = Paint()
        ..color = AppTheme.primaryTeal.withOpacity(0.3)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      final path = Path();
      path.moveTo(0, size.height * 0.75);
      path.cubicTo(size.width * 0.2, size.height * 0.5, size.width * 0.35, size.height * 0.85,
          size.width * 0.5, size.height * 0.45);
      path.cubicTo(size.width * 0.65, size.height * 0.05, size.width * 0.85, size.height * 0.65, size.width,
          size.height * 0.25);
      canvas.drawPath(path, shadowPaint);

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryTeal.withOpacity(0.2), AppTheme.primaryTeal.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      final areaPath = Path.from(path);
      areaPath.lineTo(size.width, size.height);
      areaPath.lineTo(0, size.height);
      areaPath.close();
      canvas.drawPath(areaPath, fillPaint);

      final linePaint = Paint()
        ..color = AppTheme.primaryTeal
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, linePaint);
      return;
    }

    final values = data!;
    final maxVal = values.length > 1 ? values.reduce((a, b) => a > b ? a : b) : values.first;
    final paddingTop = size.height * 0.12;
    final paddingBottom = size.height * 0.08;
    final usableHeight = size.height - paddingTop - paddingBottom;

    // build points
    final points = <Offset>[];
    if (values.length == 1) {
      // Single data point: center it horizontally
      final normalized = maxVal > 0 ? (values[0] / maxVal) : 0.0;
      final y = paddingTop + (1 - normalized) * usableHeight;
      points.add(Offset(size.width * 0.5, y));
    } else {
      for (var i = 0; i < values.length; i++) {
        final x = (i / (values.length - 1)) * size.width;
        final normalized = maxVal > 0 ? (values[i] / maxVal) : 0.0;
        final y = paddingTop + (1 - normalized) * usableHeight;
        points.add(Offset(x, y));
      }
    }

    // create smooth path
    final path = Path();
    if (points.length == 1) {
      path.addOval(Rect.fromCircle(center: points.first, radius: 0.1));
    } else {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
        path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
      }
      path.lineTo(points.last.dx, points.last.dy);
    }

    // area fill
    final areaPath = Path.from(path);
    areaPath.lineTo(size.width, size.height);
    areaPath.lineTo(0, size.height);
    areaPath.close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.primaryTeal.withOpacity(0.22), AppTheme.primaryTeal.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, fillPaint);

    // line
    final linePaint = Paint()
      ..color = AppTheme.primaryTeal
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // glowing points
    final glowPaint = Paint()
      ..color = AppTheme.primaryTeal
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final dotPaint = Paint()..color = Colors.white;
    for (int i = 0; i < points.length; i++) {
      final isSelected = (selectedPoint != null && selectedPoint == i);
      final p = points[i];
      canvas.drawCircle(p, isSelected ? 10 : 6, glowPaint);
      canvas.drawCircle(p, isSelected ? 5.5 : 3.5, Paint()..color = AppTheme.primaryTeal);
      canvas.drawCircle(p, isSelected ? 3.5 : 1.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SophisticatedAreaChartPainter oldDelegate) =>
      oldDelegate.selectedPoint != selectedPoint || !listEquals(oldDelegate.data, data);
}
