import 'package:donation_app/screens/donor_new/donor_donation_form.dart';
import 'package:flutter/material.dart';
import 'package:donation_app/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:donation_app/providers/donation_provider.dart';
import 'package:donation_app/models/donation_model.dart';

class DonorDonationsPage extends StatefulWidget {
  const DonorDonationsPage({super.key});

  @override
  _DonorDonationsPageState createState() => _DonorDonationsPageState();
}

class _DonorDonationsPageState extends State<DonorDonationsPage> {
  late User? _currentUser;

  @override
  void initState() {
    super.initState();
    // fetch user details
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      // execute initialization of the stream after the layout is completed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .read<DonationProvider>()
            .fetchDonationsByDonor(_currentUser!.uid);
      });
    }
  }

  Future<String> _fetchOrgName(String orgId) async {
    final userDetails =
        await context.read<MyAuthProvider>().getUserDetails(orgId);
    return userDetails['name'] as String? ?? 'Unknown Organization';
  }

  int _countDonations(List<Donation> donations, String status) {
    return donations
        .where((donation) => donation.status.toLowerCase() == status)
        .length;
  }

  Tab _buildStatusTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              constraints: const BoxConstraints(minWidth: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFF54741),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonationList(List<Donation> donations, String status) {
    List<Donation> filteredDonations = donations.where((donation) {
      return donation.status.toLowerCase() == status.toLowerCase();
    }).toList();

    if (filteredDonations.isEmpty) {
      return Center(
        child: Text(
          'No ${status.toLowerCase() == 'scheduled for pick-up' ? 'scheduled' : status.toLowerCase()} donations yet!',
          style: const TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredDonations.length,
      itemBuilder: (context, index) {
        Donation donation = filteredDonations[index];
        return FutureBuilder<String>(
          future: _fetchOrgName(donation.orgId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // return const LinearProgressIndicator();
              return Container(); // TODO: Find fix for progress indicator stacking
            } else if (snapshot.hasError) {
              return Text('Error encountered! ${snapshot.error}');
            }
            String orgName = snapshot.data ?? 'Organization';
            return _buildDonationCard(donation, orgName);
          },
        );
      },
    );
  }

  Widget _buildDonationCard(Donation donation, String orgName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () {
          // change selected donation
          context.read<DonationProvider>().changeSelectedDonation(donation);

          // navigate to the donation details page
          Navigator.push(
            context,
            MaterialPageRoute(
              // builder: (context) => const DonationDetailsPage(),
              builder: (context) => const DonorDonationFormPage(mode: 'view'),
            ),
          );
        },
        child: Card(
          surfaceTintColor: Colors.transparent,
          child: ListTile(
            title: Text(
              orgName, // display the fetched donor name
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1, // limit name to one line
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Donated on ${DateFormat('MMMM dd, yyyy').format(donation.timestamp)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1, // limit date to one line
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  // limit categories to be displayed to 3
                  children: donation.categories.take(3).map((category) {
                    return _buildTruncatedChip(category);
                  }).toList(),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildTruncatedChip(String text) {
    const maxLength = 20;
    final truncatedText =
        text.length > maxLength ? '${text.substring(0, maxLength)}...' : text;

    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      label: Text(truncatedText),
      backgroundColor: Theme.of(context).colorScheme.primary,
      side: BorderSide.none,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    // access donations in the provider
    Stream<QuerySnapshot> donationsStream =
        context.watch<DonationProvider>().donationsByDonor;

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream: donationsStream,
      builder: (context, snapshot) {
        // convert data from donations stream to a list
        final List<Donation> donations = <Donation>[];
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final Donation donation =
                Donation.fromJson(doc.data() as Map<String, dynamic>);
            donation.id = doc.id;
            donations.add(donation);
          }
        }

        Widget body;
        if (snapshot.hasError) {
          body = Center(
            child: Text("Error encountered! ${snapshot.error}"),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          body = const Center(
            child: CircularProgressIndicator(),
          );
        } else if (donations.isEmpty) {
          body = const Center(
            child: Text(
              'No donations yet!',
              style: TextStyle(fontSize: 18),
            ),
          );
        } else {
          body = TabBarView(
            children: [
              _buildDonationList(donations, 'pending'),
              _buildDonationList(donations, 'confirmed'),
              _buildDonationList(donations, 'scheduled for pick-up'),
              _buildDonationList(donations, 'completed'),
              _buildDonationList(donations, 'cancelled'),
            ],
          );
        }

        return DefaultTabController(
          length: 5,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                "Donations",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              bottom: TabBar(
                isScrollable: true,
                dividerColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                tabs: [
                  _buildStatusTab(
                      'Pending', _countDonations(donations, 'pending')),
                  _buildStatusTab(
                      'Confirmed', _countDonations(donations, 'confirmed')),
                  _buildStatusTab('Scheduled',
                      _countDonations(donations, 'scheduled for pick-up')),
                  const Tab(text: "Completed"),
                  const Tab(text: "Cancelled"),
                ],
              ),
            ),
            body: body,
          ),
        );
      },
    );
  }
}
