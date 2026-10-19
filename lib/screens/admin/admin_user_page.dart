import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'admin_donor_donations_list.dart';
import 'admin_org_donations_list.dart';
import 'admin_user_account_details.dart';

class UserPage extends StatefulWidget {
  final User user;

  const UserPage({Key? key, required this.user}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.user.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFF54741),
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFFF54741)),
          bottom: TabBar(
            dividerColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            tabs: [
              widget.user.role == 'org'
                  ? const Tab(text: 'Donation Drives')
                  : const Tab(text: 'Donations'),
              const Tab(text: 'Account Details'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            widget.user.role == 'org'
                ? OrgDonationsList(orgId: widget.user.id!)
                : DonorDonationsList(donorId: widget.user.id!),
            UserAccountDetails(user: widget.user)
          ],
        ),
      ),
    );
  }
}
