part of '../main.dart';

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: const Color(0xFFC88F52)),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(body, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConstrainedPage extends StatelessWidget {
  const _ConstrainedPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: child,
      ),
    );
  }
}

class _StorefrontPage extends StatelessWidget {
  const _StorefrontPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: child,
      ),
    );
  }
}

class MaintenanceView extends StatelessWidget {
  const MaintenanceView({super.key, required this.message, this.onAdminAccess});

  final String message;
  final VoidCallback? onAdminAccess;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height - 120,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: MediaQuery.sizeOf(context).width.clamp(320, 620),
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 28),
                Text(
                  'Something beautiful is being prepared',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Thank you for giving us a moment to make your next visit feel even better.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
                if (onAdminAccess != null) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: onAdminAccess,
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Admin access'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String currency(double value) => '\$${value.toStringAsFixed(2)}';
