import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectDisplayPage extends StatefulWidget {
  final Map<String, dynamic> projectData;
  final String currentUserEmail;
  final String firstname;
  final String lastname;

  const ProjectDisplayPage({
    Key? key,
    required this.projectData,
    required this.currentUserEmail,
    required this.firstname,
    required this.lastname,
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
  bool isLoading = true;

  // Controllers for editable fields
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _projectTypeController;
  late TextEditingController _githubLinkController;

  // UI Theme colors
  final Color primaryColor = const Color(0xFF3A0CA3);
  final Color accentColor = const Color(0xFF4361EE);
  final Color highlightColor = const Color(0xFF4CC9F0);
  final Color secondaryAccentColor = const Color(0xFF7209B7);
  final Color backgroundStartColor = const Color(0xFF3A0CA3);
  final Color backgroundEndColor = const Color(0xFF4CC9F0);
  final Color cardColor = Colors.white.withOpacity(0.95);

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

    // Load comments from Firestore
    _loadComments();
  }

  void _loadComments() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (widget.projectData['id'] != null) {
        await _loadCommentsFromFirestore();
      } else {
        // If no project ID, load mock comments
        print("line 81");
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading comments: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCommentsFromFirestore() async {
    setState(() {
      isLoading = true;
    });

    try {
      final projectId = widget.projectData['id']?.toString();
      if (projectId == null || projectId.isEmpty) {
        print('Project ID is null or empty');

        return;
      }

      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('projectId', isEqualTo: projectId)
          .orderBy('timestamp', descending: true)
          .get();

      if (commentsSnapshot.docs.isNotEmpty) {
        setState(() {
          comments = commentsSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'userId': data['userId'] ?? '',
              'userName': data['userName'] ?? 'Anonymous',
              'text': data['text'] ?? '',
              'timestamp': (data['timestamp'] as Timestamp).toDate(),
              'isOwner': data['isOwner'] ?? false,
              'projectId': data['projectId'] ?? '',
            };
          }).toList();
        });
      } else {
        print('No comments found in Firestore');

      }
    } catch (error) {
      print('Error loading comments: $error');
      if (error is FirebaseException && error.code == 'failed-precondition') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Missing Firestore index. Please contact support.'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }



  Future<void> _addComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    // Get current user info
    String userName = widget.firstname +" " + widget.lastname;
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && currentUser.displayName != null) {
        userName = currentUser.displayName!;
      } else if (isOwner) {
        userName = '${widget.projectData['submitter']['firstName'] ?? ''} ${widget.projectData['submitter']['lastName'] ?? ''}'.trim();
      }
    } catch (e) {
      print('Error getting user display name: $e');
    }

    // Get project ID - ensure we're using the correct field name
    final projectId = widget.projectData['id'] ?? widget.projectData['projectId'];

    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Project ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newComment = {
      'userId': widget.currentUserEmail,
      'userName': userName,
      'text': commentText,  // Use the trimmed text we saved earlier
      'timestamp': DateTime.now(),
      'isOwner': isOwner,
      'projectId': projectId,  // Use the project ID we extracted
    };

    // Show optimistic update first
    setState(() {
      comments.insert(0, newComment);
      _commentController.clear();  // Clear only after we've used the text
    });

    try {
      // Save comment to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('comments')
          .add(newComment);  // Use the complete newComment map

      // Update the comment with the firestore ID
      if (mounted) {
        setState(() {
          comments[0]['id'] = docRef.id;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding comment: $error'),
            backgroundColor: Colors.red,
          ),
        );

        // Remove the comment on error
        setState(() {
          comments.removeAt(0);
        });
      }
    }
  }

  Future<void> _deleteComment(int index) async {
    final commentId = comments[index]['id'];

    // Only allow deleting if:
    // 1. User is the comment owner, or
    // 2. User is the project owner
    final bool isCommentOwner = comments[index]['userId'] == widget.currentUserEmail;

    if (!isCommentOwner && !isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete your own comments'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Remove locally first (optimistic update)
    final deletedComment = comments[index];
    setState(() {
      comments.removeAt(index);
    });

    try {
      await FirebaseFirestore.instance
          .collection('comments')
          .doc(commentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      // If deletion fails, add the comment back
      setState(() {
        comments.insert(index, deletedComment);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting comment: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  Future<void> _saveChanges() async {
    // Update the editable data
    setState(() {
      _editableProjectData['name'] = _nameController.text;
      _editableProjectData['description'] = _descriptionController.text;
      _editableProjectData['projectType'] = _projectTypeController.text;
      _editableProjectData['githubLink'] = _githubLinkController.text;
      isEditMode = false;
    });

    // Update in Firestore
    if (widget.projectData['id'] != null) {
      try {
        await FirebaseFirestore.instance
            .collection('Projects')
            .doc(widget.projectData['id'])
            .update({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'projectType': _projectTypeController.text,
          'githubLink': _githubLinkController.text,
          'lastUpdated': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Project updated successfully!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating project: $error'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      // Show confirmation for demo purposes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Project updated successfully!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            "Project Details",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: primaryColor.withOpacity(0.8),
          elevation: 0,
          centerTitle: true,
          flexibleSpace: ClipRRect(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.8), accentColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          actions: [
            if (isOwner)
              IconButton(
                icon: Icon(
                  isEditMode ? Icons.save_rounded : Icons.edit_rounded,
                  color: Colors.white,
                ),
                onPressed: isEditMode ? _saveChanges : _toggleEditMode,
                tooltip: isEditMode ? 'Save Changes' : 'Edit Project',
              ),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [backgroundStartColor, backgroundEndColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                  // Project Details Card
                  Card(
                  color: cardColor,
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Project Name
                    Center(
                    child: isEditMode
                    ? TextField(
                    controller: _nameController,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: accentColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    )
                        : Text(
                    name,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                _buildSectionHeader(Icons.description_rounded, "Description", isOwner && !isEditMode),
                const SizedBox(height: 10),
                isEditMode
                    ? TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  style: TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                )
                    : Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    description,
                    style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                  ),
                ),
                const Divider(height: 40, thickness: 1),

                // Project Type
                _buildSectionHeader(Icons.category_rounded, "Project Type", isOwner && !isEditMode),
                const SizedBox(height: 10),
                isEditMode
                    ? TextField(
                  controller: _projectTypeController,
                  style: TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                )
                    : Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    projectType,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Divider(height: 40, thickness: 1),

                // Programming Languages
                _buildSectionHeader(Icons.code_rounded, "Languages", isOwner && !isEditMode),
                const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...(languagesList ?? []).map<Widget>((language) {
                              return Container(
                                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: highlightColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: highlightColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  language.toString(),
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                            // If no languages, show N/A
                            if (languagesList == null || languagesList.isEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'N/A',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
          const Divider(height: 40, thickness: 1),

        // Github Link
        _buildSectionHeader(Icons.link_rounded, "Github Link", isOwner && !isEditMode),
        const SizedBox(height: 10),
        isEditMode
            ? TextField(
          controller: _githubLinkController,
          style: TextStyle(fontSize: 16),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            prefixIcon: Icon(Icons.link, color: accentColor),
            filled: true,
            fillColor: Colors.grey.shade50,
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
                    backgroundColor: Colors.red.shade600,
                  ),
                );
              }
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.link, color: accentColor),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    githubLink,
                    style: TextStyle(
                      fontSize: 16,
                      color: accentColor,
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 40, thickness: 1),

        // Rapport
        if (rapportUrl.isNotEmpty)
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.picture_as_pdf_rounded, "Rapport", isOwner && !isEditMode),
        const SizedBox(height: 10),
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
                    backgroundColor: Colors.red.shade600,
                  ),
                );
              }
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: secondaryAccentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: secondaryAccentColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_as_pdf_rounded, color: secondaryAccentColor),
                SizedBox(width: 8),
                Text(
                  "View Project Report",
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryAccentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 40, thickness: 1),
      ],
    ),

    // Submitter Info
    Text(
    "Submitted by",
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    ),
    ),
    const SizedBox(height: 16),
    Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
    color: Colors.grey.shade50,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: Colors.grey.shade200),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.03),
    blurRadius: 5,
    offset: Offset(0, 3),
    ),
    ],
    ),
    child: Column(
    children: [
    Row(
    children: [
    CircleAvatar(
    backgroundColor: primaryColor.withOpacity(0.2),
    child: Icon(Icons.person_rounded, color: primaryColor),
    ),
    const SizedBox(width: 12),
    Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    submitterName.isEmpty ? 'Unknown' : submitterName,
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
    ),
    ),
    SizedBox(height: 4),
    Text(
    submitterEmail,
    style: TextStyle(
    fontSize: 14,
    color: Colors.grey.shade700,
    ),
    ),
    ],
    ),
    ],
    ),
    ],
    ),
    ),
    ],
    ),
    ),
    ),

    const SizedBox(height: 24),

    // Comments Section
    Card(
    color: cardColor,
    elevation: 8,
    shadowColor: Colors.black.withOpacity(0.3),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Icon(Icons.comment_rounded, color: primaryColor),
    SizedBox(width: 10),
    Text(
    "Comments",
    style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    ),
    ),
    if (comments.isNotEmpty)
    Container(
    margin: EdgeInsets.only(left: 10),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
    color: accentColor,
    borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
    '${comments.length}',
    style: TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    ],
    ),
    const SizedBox(height: 20),

    // Add Comment
    Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
    color: Colors.grey.shade50,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    "Add your comment",
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryColor,
    ),
    ),
    SizedBox(height: 10),
    Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Expanded(
    child: TextField(
    controller: _commentController,
    decoration: InputDecoration(
    hintText: "Share your thoughts...",
    hintStyle: TextStyle(color: Colors.grey.shade400),
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: accentColor, width: 2),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.all(12),
    ),
    maxLines: 3,
    style: TextStyle(fontSize: 15),
    ),
    ),
    const SizedBox(width: 12),
    ElevatedButton(
    onPressed: _addComment,
    style: ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
    ),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(Icons.send_rounded, size: 20),
    SizedBox(width: 8),
    Text('Post'),
    ],
    ),
    ),
    ],
    ),
    ],
    ),
    ),

    const SizedBox(height: 20),

    // Comments List
    if (isLoading)
    Center(
    child: Padding(
    padding: const EdgeInsets.all(20.0),
    child: CircularProgressIndicator(
    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
    ),
    ),
    )
    else if (comments.isEmpty)
    Center(
    child: Padding(
    padding: const EdgeInsets.all(30.0),
    child: Column(
    children: [
    Icon(
    Icons.chat_bubble_outline_rounded,
    size: 50,
    color: Colors.grey.shade400,
    ),
    SizedBox(height: 16),
    Text(
    'No comments yet',
    style: TextStyle(
    fontSize: 16,
    color: Colors.grey.shade600,
    fontWeight: FontWeight.w500,
    ),
    ),
    SizedBox(height: 8),
    Text(
    'Be the first to comment!',
    style: TextStyle(
    fontSize: 14,
    color: Colors.grey.shade500,
    ),
    ),
    ],
    ),
    ),
    )
    else
    ListView.separated(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    itemCount: comments.length,
    separatorBuilder: (context, index) => SizedBox(height: 16),
    itemBuilder: (context, index) => _buildCommentItem(comments[index], index),
    ),
    ],
    ),
    ),
    ),

    const SizedBox(height: 24),

    // Resubmit Button (Only for owners)
    if (isOwner && !isEditMode)
    Container(
    width: double.infinity,
    child: ElevatedButton.icon(
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
    SnackBar(
    content: Text('Project resubmitted successfully!'),
    backgroundColor: Colors.green.shade600,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
    ),
    ),
    );
    }).catchError((error) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
    content: Text('Error resubmitting project: $error'),
    backgroundColor: Colors.red.shade600,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
    ),
    ),
    );
    });
    } else {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
    content: Text('Project resubmitted successfully!'),
    backgroundColor: Colors.green.shade600,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
    ),
    ),
    );
    }
    },
    icon: Icon(Icons.refresh_rounded),
    label: Text(
    "Resubmit Project",
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green.shade600,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    elevation: 3,
    ),
    ),
    ),

    SizedBox(height: 30),
    ],
    ),
    ),
    ),
    ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, bool showEditIcon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (showEditIcon) ...[
          const Spacer(),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit_rounded, size: 16, color: accentColor),
            ),
            onPressed: _toggleEditMode,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Edit $title',
          ),
        ],
      ],
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, int index) {
    final bool isCommentOwner = comment['userId'] == widget.currentUserEmail;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: comment['isOwner']
            ? accentColor.withOpacity(0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: comment['isOwner']
              ? accentColor.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: comment['isOwner']
                    ? secondaryAccentColor.withOpacity(0.2)
                    : primaryColor.withOpacity(0.1),
                radius: 18,
                child: Text(
                  (comment['userName'] as String).isNotEmpty
                      ? (comment['userName'] as String)[0].toUpperCase()
                      : 'A',
                  style: TextStyle(
                    color: comment['isOwner'] ? secondaryAccentColor : primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment['userName'] ?? 'Anonymous',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(width: 8),
                        if (comment['isOwner'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: secondaryAccentColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Owner',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d, yyyy · h:mm a').format(comment['timestamp']),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwner || isCommentOwner)
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                  onPressed: () => _deleteComment(index),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  tooltip: 'Delete comment',
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 46, top: 8, right: 8),
            child: Text(
              comment['text'] ?? '',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}