import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'addProject.dart'; // File for adding a project.
import 'chat_page.dart';
import 'main.dart'; // Your login page file.
import 'profile_page.dart'; // Added the profile page import
import 'projectDisplay.dart'; // File for displaying project details.

class HomePage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;

  const HomePage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter variables
  bool _showFilters = false;
  String? _selectedProjectType;
  final List<String> _projectTypes = [
    'All Types',
    'PFE',
    'PFA',
    'Projet Academique',
    'Projet Personnel',
    'Autre',
  ];

  Map<String, bool> _selectedLanguages = {
    'Dart': false,
    'PHP': false,
    'JavaScript': false,
    'Python': false,
    'Java': false,
    'C++': false,
    'Other': false,
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _selectedProjectType = 'All Types';
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  // Disconnect function: Clears stored login data and signs out.
  void _disconnect(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyHomePage(title: "Login")),
    );
  }

  // Profile page navigation
  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          firstName: widget.firstName,
          lastName: widget.lastName,
          email: widget.email,
        ),
      ),
    );
  }

  // Uploads page navigation
  void _navigateToUploads(BuildContext context) {
    // Navigate to uploads page
    // Replace with actual uploads page navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploads page coming soon')),
    );
  }

  // Reset filters
  void _resetFilters() {
    setState(() {
      _selectedProjectType = 'All Types';
      _selectedLanguages.forEach((key, value) {
        _selectedLanguages[key] = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset : false,
      appBar: AppBar(
        title: const Text(
          "Projects Hub",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          // Filter icon
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Filter projects',
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.deepPurple.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child:SingleChildScrollView(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${widget.firstName} ${widget.lastName}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.deepPurple),
                title: const Text(
                  'Profile',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _navigateToProfile(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file, color: Colors.deepPurple),
                title: const Text(
                  'My Uploads',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _navigateToUploads(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.deepPurple),
                title: const Text(
                  'Disconnect',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _disconnect(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Persistent search bar
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
                shadowColor: Colors.deepPurple.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search projects...',
                      prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                      border: InputBorder.none,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                          : null,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Filters section (expandable)
              if (_showFilters)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 4,
                    shadowColor: Colors.deepPurple.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.tune,
                                    color: Colors.deepPurple,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Filters",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _resetFilters,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text("Reset"),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Project Type Filter
                          const Text(
                            "Project Type:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: _projectTypes.map((type) {
                                final isSelected = _selectedProjectType == type;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text(type),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedProjectType = selected ? type : 'All Types';
                                      });
                                    },
                                    backgroundColor: Colors.grey[200],
                                    selectedColor: Colors.deepPurple.withOpacity(0.2),
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.deepPurple : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Programming Languages Filter
                          const Text(
                            "Programming Languages:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _selectedLanguages.keys.map((lang) {
                              return FilterChip(
                                label: Text(lang),
                                selected: _selectedLanguages[lang]!,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedLanguages[lang] = selected;
                                  });
                                },
                                backgroundColor: Colors.grey[200],
                                selectedColor: Colors.deepPurple.withOpacity(0.2),
                                checkmarkColor: Colors.deepPurple,
                                labelStyle: TextStyle(
                                  color: _selectedLanguages[lang]! ? Colors.deepPurple : Colors.black87,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Section Title for Projects
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Row(
                  children: const [
                    Icon(Icons.folder_special, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      "Discover Projects",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),

              // Responsive Grid of Projects fetched from Firestore with search and filters.
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount;
                  double cardHeight;
                  double cardWidth;

                  if (constraints.maxWidth < 600) {
                    // Mobile: 1 column, taller cards
                    crossAxisCount = 1;
                    cardHeight = 220;
                    cardWidth = constraints.maxWidth - 32;
                  } else if (constraints.maxWidth < 1024) {
                    // Tablet: 2 columns, medium-sized cards
                    crossAxisCount = 2;
                    cardHeight = 200;
                    cardWidth = (constraints.maxWidth / 2) - 24;
                  } else {
                    // Desktop: 3 columns, wider cards
                    crossAxisCount = 3;
                    cardHeight = 180;
                    cardWidth = (constraints.maxWidth / 3) - 24;
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream:
                    FirebaseFirestore.instance
                        .collection('Projects')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  'Error: ${snapshot.error}',
                                  style: const TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.folder_open, size: 48, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No projects found',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Apply filters
                      var filteredProjects = snapshot.data!.docs;

                      // Filter by search query
                      if (_searchQuery.isNotEmpty) {
                        filteredProjects = filteredProjects.where((doc) {
                          final projectData = doc.data() as Map<String, dynamic>;
                          final projectName = (projectData['name'] ?? '').toString().toLowerCase();
                          final projectDescription = (projectData['description'] ?? '').toString().toLowerCase();
                          final query = _searchQuery.toLowerCase();
                          return projectName.contains(query) || projectDescription.contains(query);
                        }).toList();
                      }

                      // Filter by project type
                      if (_selectedProjectType != 'All Types') {
                        filteredProjects = filteredProjects.where((doc) {
                          final projectData = doc.data() as Map<String, dynamic>;
                          return projectData['projectType'] == _selectedProjectType;
                        }).toList();
                      }

                      // Filter by programming languages
                      final selectedLanguageList = _selectedLanguages.entries
                          .where((entry) => entry.value)
                          .map((entry) => entry.key)
                          .toList();

                      if (selectedLanguageList.isNotEmpty) {
                        filteredProjects = filteredProjects.where((doc) {
                          final projectData = doc.data() as Map<String, dynamic>;
                          final projectLanguages = List<String>.from(projectData['programmingLanguages'] ?? []);

                          // Check if any of the selected languages match with project languages
                          return selectedLanguageList.any((lang) => projectLanguages.contains(lang));
                        }).toList();
                      }

                      if (filteredProjects.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.search_off, size: 48, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No matching projects found.\nTry adjusting your filters.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: cardWidth / cardHeight,
                        ),
                        itemCount: filteredProjects.length,
                        itemBuilder: (context, index) {
                          final projectData = filteredProjects[index].data() as Map<String, dynamic>;
                          final String projectId = filteredProjects[index].id;
                          final List<dynamic>? languagesList = projectData['programmingLanguages'];
                          final List<String> languages = languagesList != null
                              ? List<String>.from(languagesList)
                              : [];

                          // Check if current user is the project owner
                          final Map<String, dynamic> submitter = projectData['submitter'] is Map<String, dynamic>
                              ? projectData['submitter']
                              : {};
                          final String submitterEmail = submitter['email'] ?? '';
                          final bool isOwner = submitterEmail == widget.email;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProjectDisplayPage(
                                    projectData: {
                                      ...projectData, // Spread all existing project data
                                      'id': projectId, // Add the document ID to the data
                                    },
                                    currentUserEmail: FirebaseAuth.instance.currentUser?.email ?? '', // Add this line
                                    firstname: widget.firstName,
                                    lastname: widget.lastName,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              elevation: 4,
                              shadowColor: Colors.deepPurple.withOpacity(0.3),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.0),
                                  gradient: LinearGradient(
                                    colors: isOwner
                                        ? [Colors.deepPurple.withOpacity(0.1), Colors.white]
                                        : [Colors.white, Colors.white],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              projectData['name'] ?? 'No Name',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepPurple,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isOwner)
                                            const Tooltip(
                                              message: 'Your Project',
                                              child: Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 20,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          projectData['projectType'] ?? 'N/A',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.deepPurple.shade700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        projectData['description'] ?? 'No description',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      if (languages.isNotEmpty)
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: languages.take(3).map((lang) => Chip(
                                            label: Text(
                                              lang,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: Colors.deepPurple,
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            visualDensity: VisualDensity.compact,
                                          )).toList(),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "btn1",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProjectPage(
                      firstName: widget.firstName,
                      lastName: widget.lastName,
                      email: widget.email,
                    ),
                  ),
                );
              },
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Add Project',
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: "btn2",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatPage()),
                );
              },
              backgroundColor: Colors.green,
              child: const Icon(Icons.chat, color: Colors.white),
              tooltip: 'Chat',
            ),
          ],
        ),
      ),
    );
  }
}