import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add Firebase import
import 'package:firebase_auth/firebase_auth.dart';

class ProjectDisplayPage extends StatefulWidget {
  final Map<String, dynamic> projectData;
  final String currentUserEmail;

  const ProjectDisplayPage({
    Key? key,
    required this.projectData,
    required this.currentUserEmail,
  }) : super(key: key);

  @override
  State<ProjectDisplayPage> createState() => _ProjectDisplayPageState();
}

class _ProjectDisplayPageState extends State<ProjectDisplayPage> {
  late Map<String, dynamic> _editableProjectData;
  late bool isOwner;
  late TextEditingController _commentController;
  List<Map<String, dynamic>> comments = [];
  bool isEditMode = false;

  // Controllers for editable fields
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _projectTypeController;
  late TextEditingController _githubLinkController;

  @override
  void initState() {
    super.initState();
    _editableProjectData = Map<String, dynamic>.from(widget.projectData);

    // Check if current user is owner
    final Map<String, dynamic> submitter =
    widget.projectData['submitter'] is Map<String, dynamic>
        ? widget.projectData['submitter']
        : {};
    isOwner = submitter['email'] == widget.currentUserEmail;

    // Initialize controllers
    _commentController = TextEditingController();
    _nameController = TextEditingController(text: _editableProjectData['name'] ?? '');
    _descriptionController = TextEditingController(text: _editableProjectData['description'] ?? '');
    _projectTypeController = TextEditingController(text: _editableProjectData['projectType'] ?? '');
    _githubLinkController = TextEditingController(text: _editableProjectData['githubLink'] ?? '');

    // Load comments from Firestore if project ID exists
    if (widget.projectData['id'] != null) {
      _loadCommentsFromFirestore();
    } else {
      // Mock comments for demonstration
      _loadMockComments();
    }
  }

  void _loadCommentsFromFirestore() {
    FirebaseFirestore.instance
        .collection('Projects')
        .doc(widget.projectData['id'])
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          comments = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'userId': data['userId'] ?? '',
              'userName': data['userName'] ?? 'Anonymous',
              'text': data['text'] ?? '',
              'timestamp': (data['timestamp'] as Timestamp).toDate(),
              'isOwner': data['isOwner'] ?? false,
            };
          }).toList();
        });
      } else {
        _loadMockComments(); // Load mock comments if no comments exist
      }
    });
  }

  void _loadMockComments() {
    // This would normally fetch comments from a database
    comments = [
      {
        'userId': 'user@example.com',
        'userName': 'Jane Smith',
        'text': 'This project looks promising! How long did it take to develop?',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
        'isOwner': false,
      },
      {
        'userId': widget.projectData['submitter']['email'] ?? '',
        'userName': '${widget.projectData['submitter']['firstName'] ?? ''} ${widget.projectData['submitter']['lastName'] ?? ''}'.trim(),
        'text': 'Thank you! It took about 3 months of development.',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        'isOwner': true,
      },
    ];
  }

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      final newComment = {
        'userId': widget.currentUserEmail,
        'userName': isOwner
            ? '${widget.projectData['submitter']['firstName'] ?? ''} ${widget.projectData['submitter']['lastName'] ?? ''}'.trim()
            : 'Current User', // In a real app, get the current user's name
        'text': _commentController.text,
        'timestamp': DateTime.now(),
        'isOwner': isOwner,
      };

      setState(() {
        comments.add(newComment);
        _commentController.clear();
      });

      // Save comment to Firestore if project ID exists
      if (widget.projectData['id'] != null) {
        FirebaseFirestore.instance
            .collection('Projects')
            .doc(widget.projectData['id'])
            .collection('comments')
            .add({
          'userId': widget.currentUserEmail,
          'userName': newComment['userName'],
          'text': newComment['text'],
          'timestamp': Timestamp.fromDate(newComment['timestamp'] as DateTime),
          'isOwner': isOwner,
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding comment: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  void _saveChanges() {
    // Update the editable data
    setState(() {
      _editableProjectData['name'] = _nameController.text;
      _editableProjectData['description'] = _descriptionController.text;
      _editableProjectData['projectType'] = _projectTypeController.text;
      _editableProjectData['githubLink'] = _githubLinkController.text;
      isEditMode = false;
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Update in Firestore
    if (widget.projectData['id'] != null) {
      FirebaseFirestore.instance
          .collection('Projects')
          .doc(widget.projectData['id'])
          .update({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'projectType': _projectTypeController.text,
        'githubLink': _githubLinkController.text,
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating project: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _projectTypeController.dispose();
    _githubLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Extract project data
    final String name = _editableProjectData['name'] ?? 'No Name';
    final String description = _editableProjectData['description'] ?? 'No Description';
    final String projectType = _editableProjectData['projectType'] ?? 'N/A';
    final List<dynamic>? languagesList = _editableProjectData['programmingLanguages'];
    final String programmingLanguages = languagesList != null
        ? languagesList.join(', ')
        : 'N/A';
    final String githubLink = _editableProjectData['githubLink'] ?? 'N/A';
    final String rapportUrl = _editableProjectData['rapportUrl'] ?? '';
    final Map<String, dynamic> submitter =
    _editableProjectData['submitter'] is Map<String, dynamic>
        ? _editableProjectData['submitter']
        : {};
    final String submitterName =
    "${submitter['firstName'] ?? ''} ${submitter['lastName'] ?? ''}".trim();
    final String submitterEmail = submitter['email'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Details"),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (isOwner)
            IconButton(
              icon: Icon(isEditMode ? Icons.save : Icons.edit),
              onPressed: isEditMode ? _saveChanges : _toggleEditMode,
              tooltip: isEditMode ? 'Save Changes' : 'Edit Project',
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Project Details Card
              Card(
                color: Colors.white.withOpacity(0.92),
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project Name
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            isEditMode
                                ? Expanded(
                              child: TextField(
                                controller: _nameController,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            )
                                : Text(
                              name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      _buildSectionHeader(Icons.description, "Description", isOwner && !isEditMode),
                      const SizedBox(height: 8),
                      isEditMode
                          ? TextField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      )
                          : Text(
                        description,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const Divider(height: 30, thickness: 1),

                      // Project Type
                      _buildSectionHeader(Icons.category, "Project Type", isOwner && !isEditMode),
                      const SizedBox(height: 8),
                      isEditMode
                          ? TextField(
                        controller: _projectTypeController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      )
                          : Text(
                        projectType,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const Divider(height: 30, thickness: 1),

                      // Programming Languages
                      _buildSectionHeader(Icons.code, "Languages", isOwner && !isEditMode),
                      const SizedBox(height: 8),
                      Text(
                        programmingLanguages,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const Divider(height: 30, thickness: 1),

                      // Github Link
                      _buildSectionHeader(Icons.link, "Github Link", isOwner && !isEditMode),
                      const SizedBox(height: 8),
                      isEditMode
                          ? TextField(
                        controller: _githubLinkController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      )
                          : GestureDetector(
                        onTap: () async {
                          final Uri url = Uri.parse(githubLink);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not launch $githubLink'),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          githubLink,
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                      const Divider(height: 30, thickness: 1),

                      // Rapport
                      if (rapportUrl.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(Icons.picture_as_pdf, "Rapport", isOwner && !isEditMode),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final Uri url = Uri.parse(rapportUrl);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Could not launch $rapportUrl'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Text(
                                "View Report",
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline),
                              ),
                            ),
                            const Divider(height: 30, thickness: 1),
                          ],
                        ),

                      // Submitter Info
                      const Text(
                        "Submitted by",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Text(
                            submitterName,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Text(
                            submitterEmail,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Comments Section
              Card(
                color: Colors.white.withOpacity(0.92),
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Comments",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Comments List
                      ...comments.map((comment) => _buildCommentItem(comment)),

                      const SizedBox(height: 20),

                      // Add Comment
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                hintText: "Add a comment...",
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _addComment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Resubmit Button (Only for owners)
              if (isOwner && !isEditMode)
                ElevatedButton.icon(
                  onPressed: () {
                    // Implementation for resubmitting project
                    if (widget.projectData['id'] != null) {
                      FirebaseFirestore.instance
                          .collection('Projects')
                          .doc(widget.projectData['id'])
                          .update({
                        'status': 'resubmitted',
                        'resubmittedAt': Timestamp.now(),
                      }).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Project resubmitted successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error resubmitting project: $error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Project resubmitted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Resubmit Project"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, bool showEditIcon) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (showEditIcon) ...[
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Colors.deepPurple),
            onPressed: _toggleEditMode,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Edit $title',
          ),
        ],
      ],
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text(
                comment['userName'] ?? 'Anonymous',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              if (comment['isOwner'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Owner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                DateFormat('MMM d, yyyy').format(comment['timestamp']),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment['text'] ?? '',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}