import 'package:flutter/material.dart';
import '../../config/routes/app_routes.dart';

class BackButtonWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final Color color;
  final bool showLabel;
  const BackButtonWidget({Key? key, this.onTap, this.color = const Color(0xFF0B6EA8), this.showLabel = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: GestureDetector(
            onTap: onTap ?? () {
              final nav = Navigator.of(context);
              if (nav.canPop()) {
                nav.pop();
                return;
              }
              final rootNav = Navigator.of(context, rootNavigator: true);
              if (rootNav.canPop()) {
                rootNav.pop();
                return;
              }
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.12), color.withOpacity(0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.arrow_back_ios_new, size: 16, color: color),
                ),
                if (showLabel) const SizedBox(width: 8),
                if (showLabel) Text('Back', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class AppBarBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color color;
  const AppBarBackButton({Key? key, this.onTap, this.color = const Color(0xFF0B6EA8)}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap ?? () async {
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
          return;
        }
        final rootNav = Navigator.of(context, rootNavigator: true);
        if (rootNav.canPop()) {
          rootNav.pop();
          return;
        }
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      },
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 3))]),
        child: Icon(Icons.arrow_back_ios_new, size: 16, color: color),
      ),
    );
  }
}
