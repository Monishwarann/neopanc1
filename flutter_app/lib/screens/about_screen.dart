import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glass_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'About NeoPanc',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF070B14), const Color(0xFF0F172A), const Color(0xFF020617)]
                : [const Color(0xFFE0F2FE), const Color(0xFFF1F5F9), const Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 80,
            left: 20.0,
            right: 20.0,
            bottom: 32.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Section
              _buildHeroSection(context),
              const SizedBox(height: 24),

              // About NeoPanc
              _buildAboutSection(context),
              const SizedBox(height: 24),

              // Project Description Detail Cards
              _buildProjectDetails(context),
              const SizedBox(height: 24),

              // Mission & Vision
              _buildMissionVision(context),
              const SizedBox(height: 24),

              // System Workflow
              _buildSystemWorkflow(context),
              const SizedBox(height: 24),

              // Database & Cloud
              _buildDatabaseCloud(context),
              const SizedBox(height: 24),

              // Contact Information
              _buildContactSection(context),
              const SizedBox(height: 24),

              // App Information specs
              _buildAppInfo(context),
              const SizedBox(height: 24),

              // Medical Disclaimer
              _buildDisclaimer(context),
              const SizedBox(height: 40),

              // Footer
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeroSection(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      borderRadius: 24,
      color: theme.primaryColor,
      opacity: 0.05,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 1),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [theme.primaryColor, Colors.purpleAccent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: theme.colorScheme.surface,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/6.jpeg',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.healing_rounded, color: theme.primaryColor, size: 40);
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'NeoPanc',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI-Powered Pancreatic Cancer Early Detection System',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: theme.primaryColor, size: 24),
              const SizedBox(width: 10),
              Text(
                'About NeoPanc',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'NeoPanc is an AI-powered healthcare application that combines Artificial Intelligence, Machine Learning, ESP32 IoT technology, Firebase Cloud services, and saliva biomarker analysis to assist in the early prediction of pancreatic cancer.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDetails(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      'Early pancreatic cancer risk prediction',
      'Saliva biomarker analysis integration',
      'AI-assisted non-invasive healthcare metrics',
      'Real-time IoT sensor telemetry monitoring',
      'Firebase Cloud data synchronization',
      'Secure, dynamic medical report generation',
    ];

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Scope',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: details.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return Row(
                children: [
                  Icon(Icons.check_circle_outline, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      details[index],
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.85),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMissionVision(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.rocket_launch_outlined, color: Colors.blueAccent, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Our Mission',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Our mission is to make early pancreatic cancer risk assessment more accessible by combining Artificial Intelligence, IoT devices, and cloud technology into a single intelligent healthcare platform.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(24),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.visibility_outlined, color: Colors.purpleAccent, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Our Vision',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'To create an innovative AI healthcare ecosystem that enables fast, reliable, and affordable disease prediction for everyone using intelligent medical technologies.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemWorkflow(BuildContext context) {
    final theme = Theme.of(context);
    final workflowSteps = [
      'User',
      'Flutter Application',
      'Firebase Authentication',
      'Cloud Firestore',
      'ESP32 Device',
      'Flask API',
      'XGBoost AI Model',
      'Prediction Result',
      'PDF Medical Report',
      'Firebase Storage'
    ];

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Workflow',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: workflowSteps.length,
            itemBuilder: (context, index) {
              final isLast = index == workflowSteps.length - 1;
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLast
                            ? Colors.green.withOpacity(0.3)
                            : theme.primaryColor.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLast
                                ? Colors.green.withOpacity(0.1)
                                : theme.primaryColor.withOpacity(0.1),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isLast ? Colors.green : theme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            workflowSteps[index],
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      height: 20,
                      width: 2,
                      color: theme.primaryColor.withOpacity(0.3),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseCloud(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_sync_outlined, color: theme.primaryColor, size: 24),
              const SizedBox(width: 10),
              Text(
                'Database & Cloud Synchronization',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'NeoPanc integrates Firebase Authentication, Cloud Firestore, and Firebase Storage to act as the single source of truth. All user profiles, prediction history, reports, settings, notifications, analytics, and generated PDF reports are securely stored and synchronized in real time using Firebase services.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    final theme = Theme.of(context);
    final links = [
      {'label': 'Support Email', 'value': 'support@neopanc.io', 'icon': Icons.mail_outline_rounded},
    ];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact & Support',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...links.map((link) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(link['icon'] as IconData, color: theme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link['label'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          Text(
                            link['value'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    final theme = Theme.of(context);
    final info = {
      'App Version': '1.0.0',
      'Build Number': '3',
      'Database': 'Cloud Firestore',
      'Storage': 'Firebase Storage',
      'AI Model': 'XGBoost (Random Forest Fallback)',
      'Backend': 'Flask API RESTful',
      'IoT Module': 'ESP32 Device Node',
    };

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Information',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...info.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      entry.value,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 24),
          Text(
            'Privacy Policy',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'User data is securely stored in Firebase. Reports are securely stored in Firebase Storage. Personal information is protected and prediction data belongs only to the authenticated user.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
              const SizedBox(width: 8),
              Text(
                'Medical Disclaimer',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'This application provides AI-assisted prediction results for educational and research purposes only. It is not intended to replace professional medical diagnosis or treatment. Always consult a qualified healthcare professional for medical advice.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              height: 1.5,
              color: theme.colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Divider(color: theme.colorScheme.onSurface.withOpacity(0.08)),
        const SizedBox(height: 16),
        Text(
          '❤️ Developed by NeoPanc Team',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withOpacity(0.85),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '© 2026 NeoPanc. All Rights Reserved.',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}
