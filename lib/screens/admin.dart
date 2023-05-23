import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<List<String>> _userEmails;

  @override
  void initState() {
    super.initState();
    _userEmails = _getUserEmails();
  }

  Future<List<String>> _getUserEmails() async {
    QuerySnapshot _myDoc =
        await FirebaseFirestore.instance.collection('users').get();
    List<DocumentSnapshot> _myDocCount = _myDoc.docs;
    List<String> emails = _myDocCount.map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return data?['email'] as String? ?? '';
    }).toList();

    // Convert to Set to remove duplicates, then convert back to List
    List<String> uniqueEmails = emails.toSet().toList();
    return uniqueEmails;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
      ),
      body: FutureBuilder<List<String>>(
        future: _userEmails,
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Total number of users: ${snapshot.data?.length ?? 0}',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data?.length ?? 0,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(snapshot.data![index]),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
