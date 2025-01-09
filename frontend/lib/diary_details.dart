// DiaryDetailsPage.dart
import 'package:flutter/material.dart';
import 'package:memoir_lane/API/postgreSQL.dart';
import 'package:memoir_lane/diary.dart';
import 'package:memoir_lane/style.dart';

class DiaryDetailsPage extends StatefulWidget {
  final int user_id;
  final Map<String, dynamic>? diary;
  final VoidCallback onSave;

  const DiaryDetailsPage({Key? key, required this.user_id, this.diary, required this.onSave}) : super(key: key);

  @override
  State<DiaryDetailsPage> createState() => _DiaryDetailsPageState();
}

class _DiaryDetailsPageState extends State<DiaryDetailsPage> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  String? date;
  bool isModified = false;
  bool loadingAction = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.diary?['title'] ?? '');
    descriptionController = TextEditingController(text: widget.diary?['description'] ?? '');
    date = widget.diary == null ? '' : widget.diary?['date'] ?? '';
    titleController.addListener(() => setState(() => isModified = true));
    descriptionController.addListener(() => setState(() => isModified = true));
  }

  Future<void> saveDiary() async {
    final diaryData = {
      'title': titleController.text,
      'description': descriptionController.text,
      'user_id': widget.user_id
    };

    if (widget.diary == null) {
      bool result = await saveOrUpdateDiary(diaryData);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully Added Diary'),
            backgroundColor: Colors.green,
            showCloseIcon: true,
          ),
        );
        widget.onSave(); // Refresh diaries
        Navigator.pop(context); // Go back to the DiaryPage
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database Connection Lost'),
            backgroundColor: Colors.red,
            showCloseIcon: true,
          ),
        );
      }
    } else {
      bool result = await saveOrUpdateDiary(diaryData, widget.diary!['id']);

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully Updated Diary'),
            backgroundColor: Colors.green,
            showCloseIcon: true,
          ),
        );
        widget.onSave(); // Refresh diaries
        Navigator.pop(context); // Go back to the DiaryPage
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database Connection Lost'),
            backgroundColor: Colors.red,
            showCloseIcon: true,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (widget.diary != null)
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey.withAlpha(100),
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.deepPurple,
                      size: 30,
                    ),
                    onPressed: () async {
                      bool result = await deleteDiary(widget.diary!['id']);

                      if (result) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Successfully Deleted Diary'),
                            backgroundColor: Colors.green,
                            showCloseIcon: true,
                          ),
                        );
                        widget.onSave(); // Refresh diaries after deletion
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Database Connection Lost'),
                            backgroundColor: Colors.red,
                            showCloseIcon: true,
                          ),
                        );
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 10,
                )
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (date != null && date != '')
                      Row(
                        children: [
                          Text(
                            formatDate(date!),
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(hintText: 'Title'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: null,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(hintText: 'Description'),
                      maxLines: null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (loadingAction) showLoadingAction()
        ],
      ),
      floatingActionButton: isModified
          ? InkWell(
              onTap: () async {
                setState(() {
                  loadingAction = true;
                });

                await saveDiary();
                setState(() {
                  loadingAction = false;
                });
              },
              child: Container(
                width: 150,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(15)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Save',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      Icons.save_outlined,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
