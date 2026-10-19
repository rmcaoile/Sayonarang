import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import 'admin_donors.dart';
import 'admin_profile.dart';
import 'admin_org.dart';

class AdminView extends StatelessWidget {
  const AdminView({super.key});

  static const List<String> _pageTitles = [
    'Organizations',
    'Donors',
    'Profile'
  ];

  static final List<Widget> _AdminScreens = <Widget>[
    const ViewOrganizations(),
    const ViewDonors(),
    const ProfilePage()
  ];

  static const Color customRed = Color(0xFFF54741);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitles[provider.selectedIndex],
          style: const TextStyle(
            color: customRed,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _AdminScreens.elementAt(provider.selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Organizations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake),
            label: 'Donors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: provider.selectedIndex,
        selectedItemColor: customRed,
        onTap: (index) => provider.updateIndex(index),
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}
