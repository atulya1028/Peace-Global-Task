import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ViewRecords extends StatefulWidget {
  const ViewRecords({Key? key}) : super(key: key);

  @override
  State<ViewRecords> createState() => _ViewRecordsState();
}

class _ViewRecordsState extends State<ViewRecords> {

  String imageUrl = '';

  final picker = ImagePicker();

  final nameController =TextEditingController();
  final cityController =TextEditingController();

  Future _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _cropImage(File(pickedFile.path));
    }
  }

  Future _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper.platform.cropImage(
      sourcePath: imageFile.path,
      aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 100,
      maxWidth: 700,
      maxHeight: 700,
      compressFormat: ImageCompressFormat.png,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Cropper',
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );
    if (croppedFile != null) {
      _uploadImage(File(croppedFile.path));
    }
  }

  final storage = FirebaseStorage.instance;

  Future<void> _uploadImage(File imageFile) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final reference = storage.ref().child('images/$fileName.jpg');
    final uploadTask = reference.putFile(imageFile);
    var _uploadProgress;

    // Listen for state changes in the upload task
    uploadTask.snapshotEvents.listen((event) {
      double progress = event.bytesTransferred / event.totalBytes;
      print('Upload progress: $progress');

      // Update the UI with the upload progress
      setState(() {
        // Set a variable to hold the progress value, and show a progress indicator
        // using the CircularProgressIndicator widget
        _uploadProgress = progress;
      });
    });

    // Wait for the upload task to complete
    final snapshot = await uploadTask;
    imageUrl = await snapshot.ref.getDownloadURL();

    // Hide the progress indicator by setting the _uploadProgress variable to null
    setState(() {
      _uploadProgress = null;
    });

    print(imageUrl);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text('Records'),
      ),
      body:StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context,AsyncSnapshot<QuerySnapshot> snapshot) {
        if(snapshot.hasData) {
          final data = snapshot.data!.docs;
          return DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 600,
              columns: [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Url')),
            DataColumn(label: Text('City')),
            DataColumn(label: Text('Delete')),
            DataColumn(label: Text('Update')),
          ], rows: data.map((item) {
            return DataRow(cells: [
              DataCell(Text(item['fullName'])),
              DataCell(Image.network(item['url'])),
              DataCell(Text(item['city'])),
              DataCell(IconButton(onPressed: () {
                FirebaseFirestore.instance.collection('users').where('fullName',isEqualTo: item['fullName']).get()
                    .then((QuerySnapshot querySnapshot) {
                  querySnapshot.docs.forEach((doc) {
                    doc.reference.delete();
                  });
                });
              },icon: Icon(Icons.delete),)),
              DataCell(IconButton(onPressed: () {
                showDialog(context: context, builder: (context) {
                  nameController.text = item['fullName'];
                  cityController.text = item['city'];
                  return AlertDialog(
                    content: SingleChildScrollView(
                      child: Column(
                        children: [
                          InkWell(
                            onTap:() {
                              _pickImage();
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipOval(
                                  child: Image.network(imageUrl,width: 100,height: 100,fit: BoxFit.fill,scale: 1,),
                                ),
                                Positioned(
                                  left: 70,
                                  top: 70,
                                  child: CircleAvatar(
                                    radius: 15,
                                    child: Icon(Icons.add),
                                  ),
                                )
                              ],
                            ),
                          ),
                          SizedBox(height: 20,),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 100),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 40,
                                  child: TextField(
                                    controller: nameController,
                                    decoration: InputDecoration(
                                        hintText: 'Enter your name',
                                        contentPadding: EdgeInsets.all(10),
                                        enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.grey,width: 1)
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.grey,width: 1)
                                        )
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20,),
                                SizedBox(
                                  height: 40,
                                  child: TextField(
                                    controller: cityController,
                                    decoration: InputDecoration(
                                        hintText: 'Enter your city',
                                        contentPadding: EdgeInsets.all(10),
                                        enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.grey,width: 1)
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.grey,width: 1)
                                        )
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20,),
                          ElevatedButton(onPressed: () {
                            FirebaseFirestore.instance.collection('users').where('fullName', isEqualTo:item['fullName'])
                                .get().then((QuerySnapshot querySnapshot) {
                              querySnapshot.docs.forEach((doc) {
                                doc.reference.update({
                                  'fullName': nameController.text,
                                  'url': imageUrl,
                                  'city': cityController.text
                                });
                              });
                            });
                            Navigator.pop(context);
                          }, child: Text('Submit')),
                        ],
                      ),
                    ),
                  );
                });
              },icon: Icon(Icons.update),)),
            ]);
          }
              ).toList());
        } else {
          return Center(child: CircularProgressIndicator(),);
        }
        },
      ),
    );
  }
}
