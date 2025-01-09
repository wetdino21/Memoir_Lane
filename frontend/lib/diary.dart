// DiaryPage.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memoir_lane/API/postgreSQL.dart';
import 'package:memoir_lane/diary_details.dart';
import 'package:memoir_lane/login.dart';

class DiaryPage extends StatefulWidget {
  final int id;

  const DiaryPage({required this.id});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  List<Map<String, dynamic>> diaries = [];
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    fetchDBDiaries();
    fetchDBUserDetails();
  }

  Future<void> fetchDBDiaries() async {
    final fetchedDiaries = await fetchDiaries(widget.id);
    setState(() {
      diaries = fetchedDiaries;
    });
  }

  Future<void> fetchDBUserDetails() async {
    final fetchedUser = await fetchUserDetails(widget.id);
    if (fetchedUser != null) {
      setState(() {
        user = fetchedUser;
        print(user);
      });
    }
  }

  Future<void> deleteDiary(int id) async {
    await deleteDiary(id);
    fetchDBDiaries(); // Refresh the list of diaries after deletion
  }

  void openDiaryDetailsPage([Map<String, dynamic>? diary]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailsPage(
          user_id: widget.id,
          diary: diary,
          onSave: fetchDBDiaries, // Pass the fetchDiaries to refresh after saving
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: Drawer(
        child: Column(
          children: [
            Flexible(
              flex: 8,
              child: user == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        UserAccountsDrawerHeader(
                          accountName: Text(user!['email']),
                          accountEmail: Text('Phone Number: ${user!['phone_number']} \nUser ID: ${user!['id']}'),
                          currentAccountPicture: user!['picture'] != null
                              ? CircleAvatar(
                                  backgroundImage: MemoryImage(
                                    base64Decode(user!['picture']),
                                  ),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                        ),
                      ],
                    ),
            ),
            Flexible(
              flex: 1,
              child: Container(
                width: 150,
                child: InkWell(
                  onTap: () {
                    logoutDialog(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchDBDiaries();
        },
        child: ListView(
          children: [
            Column(
              children: [
                PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (didPop, result) async {
                      if (didPop) {
                        return;
                      }
                    },
                    child: Container()),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Welcome to Memoir Lane!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                  ),
                ),
                diaries.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 150),
                          Icon(Icons.description, color: Colors.black45, size: 30), // Adding a relevant icon
                          SizedBox(width: 10),
                          Text(
                            'No created story yet!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black45),
                          ),
                          Text(
                            'Capture your thoughts today.',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black45),
                          ),
                        ],
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: diaries.length,
                        itemBuilder: (context, index) {
                          final diary = diaries[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(
                                diary['title'],
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(formatDate(diary['date'])),
                              onTap: () => openDiaryDetailsPage(diary),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openDiaryDetailsPage(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}

String formatDate(String dateStr) {
  DateTime dateTime = DateTime.parse(dateStr); // Assuming the date is in ISO 8601 format
  String formattedDate = DateFormat('MMM dd, yyyy (EEEE)').format(dateTime);
  return formattedDate;
}

void logoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0)), side: BorderSide(color: Colors.red, width: 0.5)),
        icon: Icon(Icons.logout, size: 50),
        iconColor: Colors.red,
        title: Text('Are you sure to logout?', style: TextStyle(color: Colors.red)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red, // Button background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Button border radius
              ),
            ),
            child: Text('Yes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[200], // Button background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Button border radius
              ),
            ),
            child: Text('Cancel', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}
