import 'package:flutter/material.dart';
import '../../core/widgets/back_button_widget.dart';
import '../../core/constants/app_colors.dart';
import '../../config/routes/app_routes.dart';

class AlertDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const AlertDetailScreen({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alert = data['alert'] as Map<String, dynamic>? ?? {};
    final student = alert['student'] as Map<String, dynamic>? ?? {};
    final theme = Theme.of(context);
    final isSecurity = data['isSecurity'] == true;
    final roleArg = isSecurity ? 'security body' : 'proctorial body';
    final initialFilter = isSecurity ? 'Forwarded' : 'All';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert details'),
        centerTitle: true,
        elevation: 0,
        leading: AppBarBackButton(onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.alerts, arguments: {'initialFilter': initialFilter, 'isSecurity': isSecurity})),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home, arguments: roleArg),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.home),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Heading under AppBar (logo + app title) similar to Alerts screen
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/splash_logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(Icons.shield, color: AppColors.primary, size: 32),
              ),
            ),
            const SizedBox(width: 8),
            Text('SafeLink - NSTU', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(alert['time'] ?? '', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(alert['location'] ?? '', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Student information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Name: ${student['name'] ?? '-'}', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text('ID: ${student['id'] ?? '-'}', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text('Phone: ${student['phone'] ?? '-'}', style: theme.textTheme.bodyMedium),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Current location', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Lat: ${student['lat'] ?? '-'}, Lng: ${student['lng'] ?? '-'}', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AlertMapScreen(student: student)));
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('View Map'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                // Show actions only for Pending alerts and only when viewing as Proctor (not Security)
                if ((alert['status'] as String?) == 'Pending' && !isSecurity)
                  SizedBox(
                    width: double.infinity,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Accept action (proctor accepts the alert)
                            await showDialog<void>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Alert accepted'),
                                content: const Text('Alert accepted by Proctorial Body'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Accept Alert'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Here you would implement actual forwarding logic.
                            await showDialog<void>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Alert Sent'),
                                content: const Text('Alert Sent to Security Body'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.send),
                          label: const Text('Forward to Security Body'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ),
                    ]),
                  ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class AlertMapScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  const AlertMapScreen({Key? key, required this.student}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder map view — replace with real map integration if needed
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        elevation: 0,
        leading: const AppBarBackButton(),
      ),
      body: Center(
        child: Container(
          width: 520,
          height: 360,
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.map, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 12),
            Text('Student location', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Lat: ${student['lat'] ?? '-'}  Lng: ${student['lng'] ?? '-'}'),
          ]),
        ),
      ),
    );
  }
}
