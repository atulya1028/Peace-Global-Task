import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:task_peace_global_llc_atulya/screens/view_records.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final nameController =TextEditingController();
  final cityController =TextEditingController();

  String imageUrl = '';

  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _cropImage(File(pickedFile.path));
    }
  }

  Future<void> _cropImage(File imageFile) async {
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

    CollectionReference users = FirebaseFirestore.instance.collection('users');

    Future<void> addUser(String fullName,String path, String city) {
      return users.add(
          {
            'fullName': fullName,
            'url': path,
            'city': city
          }
      ).then((value) =>  print('User successfully added in database')).catchError((error) => print("Error: "+error));
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                _pickImage();
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    radius: 60,
                    child: imageUrl.isEmpty ? Icon(Icons.person,size: 100,) : imageUrl.isEmpty ? Center(child: CircularProgressIndicator(),) :  CircleAvatar(
                      backgroundImage:NetworkImage(imageUrl),
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      radius: 60,
                    ),
                  ),
                  Positioned(
                    left: 80,
                    top: 90,
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
              addUser(nameController.text, imageUrl,cityController.text);
            }, child: Text('Submit')),
            SizedBox(height: 25,),
            TextButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ViewRecords()));
            }, child: Text('View Records'))
          ],
        ),
      ),
    );
  }
}