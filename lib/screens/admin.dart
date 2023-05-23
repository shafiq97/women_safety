import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart'; // used for getting the file directory
import 'dart:io'; // used for file operations

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
          child: pw.Text('Hello World',
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

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/users.pdf');
    await file.writeAsBytes(await pdf.save());
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
