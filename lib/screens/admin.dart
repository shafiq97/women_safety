import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:intl/intl.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<List<Map<String, dynamic>>> _allUserEmails;
  late Future<List<Map<String, dynamic>>> _filteredUserEmails;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  DateFormat _dateFormat = DateFormat("yyyy-MM-dd");

  @override
  void initState() {
    super.initState();
    _allUserEmails = _getUserEmails();
    _filteredUserEmails = _allUserEmails;
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

  Future<List<Map<String, dynamic>>> _applyFilter(
      List<Map<String, dynamic>> users) async {
    return users.where((user) {
      DateTime userDate =
          DateFormat.yMMMd().add_jm().parse(user['sign_in_datetime']);
      return userDate.isAfter(_startDate) && userDate.isBefore(_endDate);
    }).toList();
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
              _filteredUserEmails.then((users) => _createPdf(users));
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020, 8),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != _startDate)
                    setState(() {
                      _startDate = picked;
                    });
                },
                child: Text('Start date: ${_dateFormat.format(_startDate)}'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: DateTime(2020, 8),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != _endDate)
                    setState(() {
                      _endDate = picked;
                    });
                },
                child: Text('End date: ${_dateFormat.format(_endDate)}'),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              _allUserEmails
                  .then((users) => _applyFilter(users))
                  .then((filteredUsers) {
                setState(() {
                  _filteredUserEmails = Future.value(filteredUsers);
                });
              });
            },
            child: Text('Apply filter'),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _filteredUserEmails,
            builder: (BuildContext context,
                AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return Expanded(
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
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
