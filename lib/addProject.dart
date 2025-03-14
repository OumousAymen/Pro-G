import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class AddProjectPage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;

  const AddProjectPage({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.email,
  }) : super(key: key);

  @override
  _AddProjectPageState createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _githubLinkController = TextEditingController();

  // Project type (only one selection allowed)
  String _projectType = 'Mobile'; // default value
  final List<String> _projectTypes = ['PFE', 'PFA' ,'Projet Academique','Projet Personnel', 'Autre'];

  // Programming languages (multiple selection allowed)
  Map<String, bool> _programmingLanguages = {
    'Dart': false,
    'PHP':false,
    'JavaScript': false,
    'Python': false,
    'Java': false,
    'C++': false,

    'Other': false,
  };

  // For PDF file selection (rapport)
  File? _pdfFile;
  String? _pdfFileName;
  bool _isUploading = false;

  // Function to pick PDF file
  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _pdfFile = File(result.files.single.path!);
        _pdfFileName = result.files.single.name;
      });
    }
  }

  // Function to submit the project details to Firestore
  Future<void> _submitProject() async {
    if (!_formKey.currentState!.validate()) return;

    // Gather selected programming languages
    List<String> selectedLanguages = _programmingLanguages.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    setState(() {
      _isUploading = true;
    });

    String? pdfUrl;
    // If a PDF file is selected, upload it to Firebase Storage
    if (_pdfFile != null) {
      try {
        String filePath =
            'projects/rapport_${DateTime.now().millisecondsSinceEpoch}_${_pdfFileName}';
        final ref = FirebaseStorage.instance.ref().child(filePath);
        UploadTask uploadTask = ref.putFile(_pdfFile!);
        TaskSnapshot snapshot = await uploadTask;
        pdfUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        print('Error uploading PDF: $e');
      }
    }

    // Save the project data to Firestore under "Projects" collection
    CollectionReference projects =
    FirebaseFirestore.instance.collection('Projects');
    await projects.add({
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'projectType': _projectType,
      'programmingLanguages': selectedLanguages,
      'githubLink': _githubLinkController.text.trim(),
      'rapportUrl': pdfUrl ?? '',
      'submitter': {
        'firstName': widget.firstName,
        'lastName': widget.lastName,
        'email': widget.email,
      },
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      _isUploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Project submitted successfully')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Project"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Project Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Project Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? "Please enter the project name"
                    : null,
              ),
              const SizedBox(height: 16),
              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty
                    ? "Please enter a description"
                    : null,
              ),
              const SizedBox(height: 16),
              // Project Type (Radio Buttons)
              const Text("Project Type",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Column(
                children: _projectTypes.map((type) {
                  return RadioListTile<String>(
                    title: Text(type),
                    value: type,
                    groupValue: _projectType,
                    onChanged: (value) {
                      setState(() {
                        _projectType = value!;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Programming Languages (Checkboxes)
              const Text("Programming Languages Used",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Column(
                children: _programmingLanguages.keys.map((lang) {
                  return CheckboxListTile(
                    title: Text(lang),
                    value: _programmingLanguages[lang],
                    onChanged: (bool? value) {
                      setState(() {
                        _programmingLanguages[lang] = value!;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Github Link Field
              TextFormField(
                controller: _githubLinkController,
                decoration: const InputDecoration(
                  labelText: "Github Link",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? "Please enter the Github link"
                    : null,
              ),
              const SizedBox(height: 16),
              // Rapport PDF Picker
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _pdfFileName ?? "No PDF selected",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _pickPDF,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    child: const Text("Pick PDF"),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Submit Button
              ElevatedButton(
                onPressed: _isUploading ? null : _submitProject,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.deepPurple,
                ),
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : const Text(
                  "Submit Project",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
