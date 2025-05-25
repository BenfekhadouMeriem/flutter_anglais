import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerHeader(context),
                _buildListTile(
                  context,
                  icon: Icons.home,
                  title: 'Accueil',
                  onTap: () => Navigator.pop(context),
                ),
                /*_buildListTile(
                  context,
                  icon: Icons.person,
                  title: 'Profil',
                  onTap: () => Navigator.pop(context),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ),*/
                _buildListTile(
                  context,
                  icon: Icons.settings,
                  title: 'Paramètres',
                  onTap: () => Navigator.pop(context),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ),
                _buildListTile(
                  context,
                  icon: Icons.brightness_6,
                  title: 'Mode Sombre',
                  onTap: () {
                    // Placeholder for dark mode toggle
                    Navigator.pop(context);
                  },
                  trailing: Switch(
                    value: false, // Placeholder state
                    onChanged: (value) {
                      // Placeholder for dark mode logic
                    },
                    activeColor: Colors.pink.shade200,
                  ),
                ),
                Divider(color: Colors.grey.shade300),
                _buildListTile(
                  context,
                  icon: Icons.logout,
                  title: 'Déconnexion',
                  iconColor: Colors.red,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          //_buildFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Placeholder for profile navigation
        Navigator.pop(context);
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade200, Colors.pink.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.easeIn,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.account_circle,
                    size: 40, color: Colors.pink.shade200),
              ),
              SizedBox(height: 12),
              Text(
                "Bienvenue !",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "user@example.com",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              icon,
              color: iconColor ?? Colors.black,
              size: 24,
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            trailing: trailing,
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            onTap: null, // Handled by InkWell for custom animation
          ),
        ),
      ),
    );
  }

  /*Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Version 1.0.0",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }*/
}
