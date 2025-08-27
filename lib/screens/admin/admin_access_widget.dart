// Create this as lib/components/admin_access_widget.dart
import 'package:flutter/material.dart';
import '../../services/supabase_auth_service.dart';
import '../../routes/app_routes.dart';
import '../../theme.dart';

class AdminAccessWidget extends StatelessWidget {
  final bool showOnlyIcon;
  final Color? iconColor;
  final String? text;

  const AdminAccessWidget({
    super.key,
    this.showOnlyIcon = false,
    this.iconColor,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SupabaseAuthService.isCurrentUserAdmin(),
      builder: (context, snapshot) {
        // Only show if user is admin
        if (!snapshot.hasData || !snapshot.data!) {
          return SizedBox.shrink();
        }

        if (showOnlyIcon) {
          return IconButton(
            icon: Icon(
              Icons.admin_panel_settings,
              color: iconColor ?? Colors.orange,
            ),
            onPressed: () => AppRoutes.navigateToAdmin(context),
            tooltip: 'Admin Panel',
          );
        }

        return InkWell(
          onTap: () => AppRoutes.navigateToAdmin(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Colors.orange,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  text ?? 'Admin',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Floating Admin Access Button (can be overlaid on any screen)
class FloatingAdminButton extends StatelessWidget {
  final Alignment alignment;
  final EdgeInsets margin;

  const FloatingAdminButton({
    super.key,
    this.alignment = Alignment.topRight,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SupabaseAuthService.isCurrentUserAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return SizedBox.shrink();
        }

        return Positioned.fill(
          child: Align(
            alignment: alignment,
            child: Container(
              margin: margin,
              child: FloatingActionButton.small(
                heroTag: "admin_fab",
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                onPressed: () => AppRoutes.navigateToAdmin(context),
                child: Icon(Icons.admin_panel_settings, size: 18),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Admin Quick Actions Bottom Sheet
class AdminQuickActions {
  static void show(BuildContext context) async {
    final isAdmin = await SupabaseAuthService.isCurrentUserAdmin();
    if (!isAdmin) return;

    // Check if context is still mounted after async operation
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Admin Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Quick action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionItem(
                  context,
                  'Dashboard',
                  Icons.dashboard,
                      () => AppRoutes.navigateToAdminDashboard(context),
                ),
                _buildQuickActionItem(
                  context,
                  'Products',
                  Icons.inventory,
                      () => AppRoutes.navigateToAdminProducts(context),
                ),
                _buildQuickActionItem(
                  context,
                  'Orders',
                  Icons.shopping_cart,
                      () => AppRoutes.navigateToAdminOrders(context),
                ),
                _buildQuickActionItem(
                  context,
                  'Full Panel',
                  Icons.apps,
                      () => AppRoutes.navigateToAdmin(context),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildQuickActionItem(
      BuildContext context,
      String label,
      IconData icon,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 24),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}