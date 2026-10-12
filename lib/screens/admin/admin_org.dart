import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import 'admin_user_page.dart';
import 'admin_org_details.dart';

class ViewOrganizations extends StatefulWidget {
  const ViewOrganizations({Key? key}) : super(key: key);

  @override
  State<ViewOrganizations> createState() => _ViewOrganizationsState();
}

class _ViewOrganizationsState extends State<ViewOrganizations> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: const Color(0xFFF54741).withValues(alpha: 0.12),
            child: const TabBar(
              labelColor: Color(0xFFF54741),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFFF54741),
              tabs: [
                Tab(text: 'Approved'),
                Tab(text: 'Pending'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrganizationList(
              context,
              provider.orgList,
              'Approved Organizations',
              Icons.check_circle,
              Colors.green,
            ),
            _buildOrganizationList(
              context,
              provider.pendingList,
              'Pending Organizations',
              Icons.access_time,
              Colors.orange,
            ),
            _buildOrganizationList(
              context,
              provider.rejectedList,
              'Rejected Organizations',
              Icons.cancel,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizationList(
    BuildContext context,
    Stream<QuerySnapshot> stream,
    String title,
    IconData icon,
    Color iconColor,
  ) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error encountered! ${snapshot.error}",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No $title...',
                  style: const TextStyle(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data?.docs.length,
          itemBuilder: (context, index) {
            User org = User.fromJson(
                snapshot.data!.docs[index].data() as Map<String, dynamic>);
            org.id = snapshot.data!.docs[index].id;

            return Card(
              surfaceTintColor: Colors.transparent,
              margin:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              elevation: 4,
              child: ListTile(
                  leading: Icon(
                    icon,
                    size: 40,
                    color: iconColor,
                  ),
                  title: Text(
                    org.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    org.username,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () {
                    if (org.status == 'approved') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserPage(user: org),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ViewOrgDetails(org: org),
                        ),
                      );
                    }
                  }),
            );
          },
        );
      },
    );
  }
}
