import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io'; // used for file operations
import 'package:external_path/external_path.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<List<Map<String, dynamic>>> _userEmails;

  @override
  void initState() {
    super.initState();
    _userEmails = _getUserEmails();
  }

  Future<List<Map<String, dynamic>>> _getUserEmails() async {
    QuerySnapshot _myDoc =
        await FirebaseFirestore.instance.collection('sign_in_log').get();
    List<DocumentSnapshot> _myDocCount = _myDoc.docs;
    List<Map<String, dynamic>> users = _myDocCount.map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return {
        'email': data?['email'] as String? ?? '',
        'sign_in_datetime': DateFormat.yMMMd().add_jm().format(
            (data?['sign_in_datetime'] as Timestamp? ?? Timestamp.now())
                .toDate()),
      };
    }).toList();

    // Convert to Set to remove duplicates, then convert back to List
    List<Map<String, dynamic>> uniqueUsers = users.toSet().toList();
    return uniqueUsers;
  }

  Future<void> _createPdf(List<Map<String, dynamic>> users) async {
    final pdf = pw.Document();
    final ByteData fontData = await rootBundle.load('assets/Helvetica.ttf');
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Text('List of users',
              style: pw.TextStyle(font: ttf, fontSize: 40)),
        );
      },
    ));

    pdf.addPage(pw.Page(
      build: (pw.Context context) => pw.Center(
        child: pw.ListView.builder(
          itemCount: users.length,
          itemBuilder: (pw.Context context, int index) => pw.Text(
              '${users[index]['email']} - Last sign-in: ${users[index]['sign_in_datetime']}'),
        ),
      ),
    ));

    String paths;

    paths = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOADS);

    final file = File('$paths/users.pdf');
    await file.writeAsBytes(await pdf.save());

    // Show SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF saved in documents directory'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save to PDF',
            onPressed: () {
              _userEmails.then((users) => _createPdf(users));
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _userEmails,
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
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
                        title: Text(snapshot.data![index]['email']),
                        subtitle: Text(
                            'Last sign-in: ${snapshot.data![index]['sign_in_datetime']}'),
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
