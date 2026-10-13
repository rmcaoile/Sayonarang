import 'package:donation_app/models/donate_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:donation_app/providers/donor_provider.dart';
import 'package:donation_app/screens/donor/donation_details.dart';

class ShowDonations extends StatefulWidget {
  const ShowDonations({super.key});

  @override
  _ShowDonationsState createState() => _ShowDonationsState();
}

class _ShowDonationsState extends State<ShowDonations>
    with SingleTickerProviderStateMixin {
  late User? _currentUser;
  late Future<void> _donationsFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _tabController = TabController(length: 5, vsync: this);
    if (_currentUser != null) {
      _donationsFuture = Provider.of<DonorProvider>(context, listen: false)
          .fetchDonationsByDonor(_currentUser!.uid);
      Provider.of<DonorProvider>(context, listen: false).fetchOrgNames();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0, // Empty string for title
        bottom: TabBar(
          isScrollable: true,
          controller: _tabController,
          dividerColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Scheduled'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: FutureBuilder<void>(
        future: _donationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Consumer<DonorProvider>(
              builder: (context, donorProvider, _) {
                final donations = donorProvider.donationsList;
                final orgNames = donorProvider.orgNames;
                if (donations.isEmpty) {
                  return const Center(child: Text('No donations found'));
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDonationList(
                        donations
                            .where((d) => d.status.toLowerCase() == 'pending')
                            .toList(),
                        orgNames),
                    _buildDonationList(
                        donations
                            .where((d) => d.status.toLowerCase() == 'confirmed')
                            .toList(),
                        orgNames),
                    _buildDonationList(
                        donations
                            .where((d) => d.status.toLowerCase() == 'scheduled')
                            .toList(),
                        orgNames),
                    _buildDonationList(
                        donations
                            .where((d) => d.status.toLowerCase() == 'completed')
                            .toList(),
                        orgNames),
                    _buildDonationList(
                        donations
                            .where((d) => d.status.toLowerCase() == 'cancelled')
                            .toList(),
                        orgNames),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildDonationList(
      List<DonateData> donations, Map<String, String> orgNames) {
    if (donations.isEmpty) {
      return const Center(child: Text('No donations found'));
    }

    return ListView.builder(
      itemCount: donations.length,
      itemBuilder: (context, index) {
        final currentDonation = donations[index];
        final orgName =
            orgNames[currentDonation.orgId] ?? 'Unknown Organization';
        IconData leadingIcon;
        Color statusColor;

        switch (currentDonation.status) {
          case 'pending':
            leadingIcon = Icons.remove_circle;
            statusColor = const Color.fromARGB(255, 213, 138, 26);
            break;
          case 'confirmed':
            leadingIcon = Icons.check_circle;
            statusColor = Colors.blue;
            break;
          case 'scheduled':
            leadingIcon = Icons.check_circle;
            statusColor = Colors.blue;
            break;
          case 'completed':
            leadingIcon = Icons.check_circle;
            statusColor = Colors.green;
            break;
          case 'cancelled':
            leadingIcon = Icons.cancel;
            statusColor = Colors.red;
            break;
          default:
            leadingIcon = Icons.error;
            statusColor = Colors.black;
        }

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: Icon(
              leadingIcon,
              color: statusColor,
            ),
            title: Text(
              orgName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(
                  'Status: ${currentDonation.status}',
                  style: TextStyle(color: statusColor),
                ),
                const SizedBox(height: 10),
                Row(
                  children: currentDonation.categories
                      .take(3) // Limit to three categories
                      .map(
                        (category) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DonationDetailScreen(
                    donation: currentDonation,
                    userName: orgName,
                    userRole: 'Donor',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
