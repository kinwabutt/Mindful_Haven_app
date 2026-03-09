import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../main.dart'; // Import to access navigationKey
import 'emergency_support_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  final bool hasHistory = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Header with Profile & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back, Kinza',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Your Journey',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shield_moon_outlined, color: Colors.redAccent, size: 24),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EmergencySupportScreen()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune_rounded, color: AppTheme.textDark, size: 24),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Weekly Stats Summary Card - Dynamic Logic Applied
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryTeal.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Check-ins',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasHistory ? '12 Sessions' : '0 Sessions',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(hasHistory ? '4.8' : '0.0', 'Mood Avg'),
                      _buildStatItem(hasHistory ? '85%' : '0%', 'Stability'),
                      _buildStatItem(hasHistory ? '5d' : '0d', 'Streak'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Enhanced Empty State Section - Conditional Visibility
            if (!hasHistory)
              Center(
                child: Column(
                  children: [
                    _buildPremiumIllustration(),
                    const SizedBox(height: 32),
                    Text(
                      'Begin Your Story',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Your personal history is empty. Every journey of a thousand miles begins with a single step.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Primary Start Button
                    GestureDetector(
                      onTap: () => navigationKey.currentState?.setIndex(1),
                      child: Container(
                        width: 220,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(27),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded, color: AppTheme.primaryTeal, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Start First Check-in',
                              style: GoogleFonts.outfit(
                                color: AppTheme.primaryTeal,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (hasHistory)
              // This is where real history cards would go in the future
              Center(
                child: Text(
                  'Your Check-in History',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),

            const SizedBox(height: 20),
            
            // Suggestion Section
            Text(
              'Quick Insights',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildInsightTip('Practice breathing for 2 minutes to reduce daily stress by 15%'),
            _buildInsightTip('Your mood is usually more stable on Monday mornings'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildInsightTip(String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.primaryTeal, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(tip, style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textDark, height: 1.4, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildPremiumIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Layered Ambient Circles
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withOpacity(0.04),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
        ),
        // Main Graphical Element
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryTeal.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.auto_stories_rounded, size: 32, color: Colors.white),
        ),
        // Decorative Accents
        Positioned(
          top: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: const Icon(Icons.favorite, size: 12, color: AppTheme.primaryTeal),
          ),
        ),
      ],
    );
  }
}
