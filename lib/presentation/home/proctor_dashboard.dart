import 'package:flutter/material.dart';
import '../../config/routes/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../auth/controllers/profile_controller.dart';
import 'see_pulse_screen.dart';

class ProctorDashboard extends StatelessWidget {
  const ProctorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ProfileController.instance;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 700;
            final avatarRadius = isNarrow ? 48.0 : 72.0;
            return Column(
              children: [
                // Blue header across top
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF6EB9F9), const Color(0xFF2386DC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, isNarrow ? 12 : 18, 14, isNarrow ? 12 : 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
                                child: Image.asset('assets/images/splash_logo.png', width: 36, height: 36, fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => Icon(Icons.shield, color: AppColors.primary, size: 36),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                              Text('SafeLink', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('NSTU', style: TextStyle(fontSize: 12, color: Colors.white70)),
                            ]),
                          ],
                        ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/settings', arguments: {'role': 'proctor'}),
                          child: Container(
                            padding: const EdgeInsets.all(2.2),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.2)),
                            child: Container(
                              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [const Color(0xFF6EB9F9), const Color(0xFF2386DC)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                              child: const CircleAvatar(radius: 20, backgroundColor: Colors.transparent, child: Icon(Icons.menu, color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Enlarged professional profile card with extra padding for breathing room
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: isNarrow ? 18 : 28, horizontal: isNarrow ? 16 : 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.08), AppColors.primary.withOpacity(0.02)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.10), blurRadius: 28, offset: const Offset(0, 14)),
                      BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 0, offset: const Offset(0, -1)),
                    ],
                    border: Border.all(color: AppColors.primary.withOpacity(0.14), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      // Left accent ring + avatar
                      Container(
                        width: avatarRadius * 1.9,
                        height: avatarRadius * 1.9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.12), AppColors.primary.withOpacity(0.06)]),
                        ),
                        child: Center(
                          child: Container(
                            width: avatarRadius * 1.2,
                            height: avatarRadius * 1.2,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            child: Center(child: Icon(Icons.shield, size: avatarRadius * 0.7, color: AppColors.primary)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      // Main text block
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(height: isNarrow ? 6 : 10),
                          Text(profile.name, style: theme.textTheme.headlineSmall?.copyWith(fontSize: isNarrow ? 20 : 28, fontWeight: FontWeight.w900, color: const Color(0xFF0B3B75))),
                          const SizedBox(height: 6),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [const Color(0xFF2D7BF2), const Color(0xFF6EB9F9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [BoxShadow(color: const Color(0xFF2D7BF2).withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 6))],
                              ),
                              child: Row(children: [Icon(Icons.shield, color: Colors.white, size: 14), const SizedBox(width: 8), Text(profile.designation.isNotEmpty ? profile.designation : 'Proctor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Noakhali Science & Technology University', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary.withOpacity(0.9), fontWeight: FontWeight.w600))),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.location_on, size: 14, color: theme.iconTheme.color?.withOpacity(0.6)),
                            const SizedBox(width: 6),
                            Text('Noakhali, Bangladesh', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                          ])
                        ]),
                      ),
                      // trailing chevron removed for a cleaner professional layout
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Contact', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(children: [
                      CircleAvatar(radius: 20, backgroundColor: AppColors.primary, child: const Icon(Icons.phone, size: 18, color: Colors.white)),
                      const SizedBox(width: 12),
                      SelectableText(profile.phone, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(children: [
                      CircleAvatar(radius: 20, backgroundColor: AppColors.primary, child: const Icon(Icons.email, size: 18, color: Colors.white)),
                      const SizedBox(width: 12),
                      SelectableText(profile.email, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text('Quick Actions', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoutes.alerts),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.12), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                child: Row(children: [
                  // Centered decorative alert artwork with larger bell and clearer indicator
                  Expanded(
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: Center(
                          child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                            // Red splash behind the alert icon (SOS-style)
                            // Larger external red splash behind the triangle (more prominent)
                            Positioned(
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [Colors.red.withOpacity(0.28), Colors.red.withOpacity(0.14), Colors.transparent],
                                    center: Alignment.center,
                                    radius: 0.9,
                                  ),
                                ),
                              ),
                            ),

                            // Triangular alert icon (SOS-style) with intensified internal red radial splash
                            SizedBox(
                              width: 94,
                              height: 94,
                              child: ClipPath(
                                clipper: TriangleClipper(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [Colors.red.shade900.withOpacity(0.98), Colors.red.shade700.withOpacity(0.95), Colors.redAccent.withOpacity(0.85), Colors.red.withOpacity(0.7)],
                                      center: Alignment(0, -0.25),
                                      radius: 1.1,
                                    ),
                                    boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 8))],
                                    border: Border.all(color: Colors.white, width: 2.0),
                                  ),
                                  child: Center(child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40)),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Alerts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 18, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('View, manage and respond to alerts quickly', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.75))),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.45), size: 28),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bottom icon bar: Home (no-op) and Back (to Login)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6))]),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  // Home (already on home) - clickable but no navigation; ripple/splash provided
                  Material(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(12),
                      splashColor: AppColors.primary.withOpacity(0.18),
                      child: const SizedBox(width: 52, height: 44, child: Center(child: Icon(Icons.home_outlined, color: Colors.black54, size: 22))),
                    ),
                  ),

                  // spacer between icons
                  const SizedBox(width: 8),

                  // See Pulse - middle button
                  Material(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SeePulseScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      splashColor: AppColors.primary.withOpacity(0.18),
                      child: const SizedBox(width: 52, height: 44, child: Center(child: Icon(Icons.business, color: Colors.black54, size: 22))),
                    ),
                  ),

                  // spacer between icons
                  const SizedBox(width: 8),

                  // Back (uses provided asset if present) - returns to Login; styled to look professional
                  Material(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                      borderRadius: BorderRadius.circular(12),
                      splashColor: AppColors.primary.withOpacity(0.18),
                      child: SizedBox(
                        width: 52,
                        height: 44,
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Image.asset('assets/images/back_icon.png', fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.arrow_back, color: Colors.black54, size: 22)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Removed unused triangle clipper — replaced by a circular badge for alerts.

// Triangle clipper used for triangular alert icon
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height * 0.9);
    path.lineTo(0, size.height * 0.9);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
