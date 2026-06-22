part of '../main.dart';

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
    this.badge = 0,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final child = Badge(
      isLabelVisible: badge > 0,
      label: Text('$badge'),
      child: Icon(icon),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: MediaQuery.sizeOf(context).width < 640
          ? IconButton(
              tooltip: label,
              isSelected: selected,
              onPressed: onPressed,
              icon: child,
            )
          : TextButton.icon(
              onPressed: onPressed,
              icon: child,
              label: Text(label),
              style: TextButton.styleFrom(
                foregroundColor: selected
                    ? const Color(0xFFC88F52)
                    : Colors.white,
              ),
            ),
    );
  }
}

class _AccountMenuButton extends StatelessWidget {
  const _AccountMenuButton({
    required this.customer,
    required this.selected,
    required this.onOpenAccount,
    required this.onCreateAccount,
    required this.onOpenAdminSignIn,
    required this.showAdminSignIn,
    required this.onLogout,
  });

  final CustomerAccount? customer;
  final bool selected;
  final VoidCallback onOpenAccount;
  final VoidCallback onCreateAccount;
  final VoidCallback onOpenAdminSignIn;
  final bool showAdminSignIn;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;
    final isSignedIn = customer != null;
    final foreground = selected ? const Color(0xFFC88F52) : Colors.white;
    final icon = Icon(
      isSignedIn ? Icons.account_circle : Icons.person_outline,
      color: foreground,
    );
    final label = isSignedIn ? 'Account' : 'Sign in';

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: PopupMenuButton<_AccountMenuAction>(
        tooltip: 'Account menu',
        onSelected: (action) {
          switch (action) {
            case _AccountMenuAction.account:
            case _AccountMenuAction.signIn:
              onOpenAccount();
            case _AccountMenuAction.createAccount:
              onCreateAccount();
            case _AccountMenuAction.adminSignIn:
              onOpenAdminSignIn();
            case _AccountMenuAction.logout:
              onLogout();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: isSignedIn
                ? _AccountMenuAction.account
                : _AccountMenuAction.signIn,
            child: ListTile(
              dense: true,
              leading: Icon(isSignedIn ? Icons.receipt_long : Icons.login),
              title: Text(isSignedIn ? 'View account' : 'Log in'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (!isSignedIn)
            const PopupMenuItem(
              value: _AccountMenuAction.createAccount,
              child: ListTile(
                dense: true,
                leading: Icon(Icons.person_add_alt),
                title: Text('Create account'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          if (showAdminSignIn)
            const PopupMenuItem(
              value: _AccountMenuAction.adminSignIn,
              child: ListTile(
                dense: true,
                leading: Icon(Icons.admin_panel_settings_outlined),
                title: Text('Admin sign in'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          if (isSignedIn)
            const PopupMenuItem(
              value: _AccountMenuAction.logout,
              child: ListTile(
                dense: true,
                leading: Icon(Icons.logout),
                title: Text('Log out'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
        child: compact
            ? Padding(padding: const EdgeInsets.all(8), child: icon)
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(width: 8),
                    Text(label, style: TextStyle(color: foreground)),
                    const SizedBox(width: 2),
                    Icon(Icons.expand_more, size: 18, color: foreground),
                  ],
                ),
              ),
      ),
    );
  }
}

enum _AccountMenuAction { account, signIn, createAccount, adminSignIn, logout }
