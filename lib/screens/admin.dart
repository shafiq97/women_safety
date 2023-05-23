import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io'; // used for file operations
import 'package:external_path/external_path.dart';

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

  Future<void> _createPdf(List<String> userEmails) async {
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
          itemCount: userEmails.length,
          itemBuilder: (pw.Context context, int index) =>
              pw.Text(userEmails[index]),
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
              _userEmails.then((emails) => _createPdf(emails));
            },
          ),
        ],
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
