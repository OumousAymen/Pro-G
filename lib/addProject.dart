import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'Checker.dart';
import 'package:http/http.dart' as http;
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _githubLinkController = TextEditingController();

  String _projectType = 'Mobile';
  final List<String> _projectTypes = [
    'PFE',
    'PFA',
    'Projet Academique',
    'Projet Personnel',
    'Autre',
  ];

  Map<String, bool> _programmingLanguages = {
    'Dart': false,
    'PHP': false,
    'JavaScript': false,
    'Python': false,
    'Java': false,
    'C++': false,
    'Other': false,
  };

  File? _pdfFile;
  String? _pdfFileName;
  bool _isUploading = false;

  Uint8List? _pdfBytes;

  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // important for web to get bytes
    );
    if (result != null) {
      setState(() {
        _pdfFileName = result.files.single.name;
        _pdfBytes = result.files.single.bytes; // for web
        if (!kIsWeb) {
          _pdfFile = io.File(result.files.single.path!); // for Android/iOS
        }
      });
    }
  }


  Future<void> _submitProject() async {
    if (!_formKey.currentState!.validate()) return;

    final String name = _nameController.text.trim();
    final String description = _descriptionController.text.trim();
    final String github = _githubLinkController.text.trim();

    if (isInappropriateProjectName(name) ||
        isInappropriateProjectName(description) ||
        isInappropriateProjectName(github)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Input contains inappropriate content.')),
      );
      return;
    }

    if (!isValidGithubLink(github)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid GitHub link.')),
      );
      return;
    }

    List<String> selectedLanguages = _programmingLanguages.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    setState(() {
      _isUploading = true;
    });

    try {
      // Generate Firestore project ID in advance
      final projectDoc = FirebaseFirestore.instance.collection('Projects').doc();
      final projectId = projectDoc.id;

      // Upload PDF to FastAPI backend
      if (_pdfFileName != null && (_pdfFile != null || _pdfBytes != null)) {
        final uri = Uri.parse('http://127.0.0.1:8000/upload/$projectId');
        final request = http.MultipartRequest('POST', uri);

        if (kIsWeb) {
          // Web: upload from bytes
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              _pdfBytes!,
              filename: _pdfFileName,
              contentType: MediaType('application', 'pdf'),
            ),
          );
        } else {
          // Android/iOS: upload from file
          request.files.add(
            await http.MultipartFile.fromPath(
              'file',
              _pdfFile!.path,
              filename: path.basename(_pdfFile!.path),
              contentType: MediaType('application', 'pdf'),
            ),
          );
        }

        final response = await request.send();
        if (response.statusCode != 200) {
          throw Exception('PDF upload failed with status ${response.statusCode}');

        }
      }

      // Save metadata to Firestore
      await projectDoc.set({
        'name': name,
        'description': description,
        'projectType': _projectType,
        'programmingLanguages': selectedLanguages,
        'githubLink': github,
        'rapportUrl': '', // Optionally generate a URL from your backend
        'submitter': {
          'firstName': widget.firstName,
          'lastName': widget.lastName,
          'email': widget.email,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project submitted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error during submission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
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
              // Project Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Project Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return "Please enter the project name";
                  if (isInappropriateProjectName(v))
                    return "Inappropriate content detected";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return "Please enter a description";
                  if (isInappropriateProjectName(v))
                    return "Inappropriate content detected";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Project Type (unchanged)
              const Text(
                "Project Type",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Column(
                children:
                    _projectTypes.map((type) {
                      return RadioListTile<String>(
                        title: Text(type),
                        value: type,
                        groupValue: _projectType,
                        onChanged: (value) {
                          setState(() => _projectType = value!);
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Programming Languages (unchanged)
              const Text(
                "Programming Languages Used",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Column(
                children:
                    _programmingLanguages.keys.map((lang) {
                      return CheckboxListTile(
                        title: Text(lang),
                        value: _programmingLanguages[lang],
                        onChanged: (bool? val) {
                          setState(() => _programmingLanguages[lang] = val!);
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // GitHub Link with validator
              TextFormField(
                controller: _githubLinkController,
                decoration: const InputDecoration(
                  labelText: "Github Link",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return "Please enter the GitHub link";
                  if (isInappropriateProjectName(v))
                    return "Inappropriate content detected";
                  if (!isValidGithubLink(v)) return "Invalid GitHub link";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // PDF picker row
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
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Pick PDF"),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _isUploading ? null : _submitProject,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.deepPurple,
                ),
                child:
                    _isUploading
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
