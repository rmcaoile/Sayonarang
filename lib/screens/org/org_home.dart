import 'package:donation_app/screens/org/org_donation_form.dart';
import 'package:donation_app/screens/donor_new/donation_card.dart';
import 'package:flutter/material.dart';
import 'package:donation_app/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:donation_app/providers/donation_provider.dart';
import 'package:donation_app/models/donation_model.dart';

class OrgHomePage extends StatefulWidget {
  const OrgHomePage({super.key});

  @override
  _OrgHomePageState createState() => _OrgHomePageState();
}

class _OrgHomePageState extends State<OrgHomePage> {
  late User? _currentUser;

  @override
  void initState() {
    super.initState();
    // TODO: Remove, move implementation to org profile page
    // fetch user details
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      // execute initialization of the stream after the layout is completed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DonationProvider>().fetchDonationsToOrg(_currentUser!.uid);
      });
    }
  }

  Future<String> _fetchDonorName(String donorId) async {
    final userDetails =
        await context.read<MyAuthProvider>().getUserDetails(donorId);
    return userDetails['name'] as String? ?? 'Unknown Donor';
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
          future: _fetchDonorName(donation.donorId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // return const LinearProgressIndicator();
              return Container(); // TODO: Find fix for progress indicator stacking
            } else if (snapshot.hasError) {
              return Text('Error encountered! ${snapshot.error}');
            }
            String donorName = snapshot.data ?? 'Donor';
            return _buildDonationCard(donation, donorName);
          },
        );
      },
    );
  }

  Widget _buildDonationCard(Donation donation, String donorName) {
    return DonationCard(
      donation: donation,
      orgName: donorName,
      onTap: () {
        // change selected donation
        context.read<DonationProvider>().changeSelectedDonation(donation);

        // navigate to the donation details page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OrgDonationFormPage(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // access donations in the provider
    Stream<QuerySnapshot> donationsStream =
        context.watch<DonationProvider>().donationsToOrg;

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
