import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // Your login page file.
import 'addProject.dart'; // File for adding a project.
import 'projectDisplay.dart'; // File for displaying project details.

class HomePage extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String email;

  const HomePage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Colors.deepPurple,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.deepPurple),
              onPressed: () => _disconnect(context),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Welcome Card with user details.
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        "Welcome, $firstName $lastName!",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Email: $email",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Responsive Grid of Projects fetched from Firestore.
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount;
                  double cardHeight;
                  double cardWidth;

                  if (constraints.maxWidth < 600) {
                    // Mobile: 2 columns, taller cards.
                    crossAxisCount = 2;
                    cardHeight = 120;
                    cardWidth = 140;
                  } else if (constraints.maxWidth < 1024) {
                    // Tablet: 3 columns, medium-sized cards.
                    crossAxisCount = 3;
                    cardHeight = 100;
                    cardWidth = 160;
                  } else {
                    // Desktop: 4 columns, smaller cards.
                    crossAxisCount = 4;
                    cardHeight = 80;
                    cardWidth = 180;
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Projects')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No projects found'));
                      }
                      final projects = snapshot.data!.docs;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: cardWidth / cardHeight,
                        ),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final projectData =
                          projects[index].data() as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProjectDisplayPage(
                                    projectData: projectData,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              elevation: 4,
                              child: SizedBox(
                                height: cardHeight,
                                width: cardWidth,
                                child: Center(
                                  child: Text(
                                    projectData['name'] ?? 'No Name',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
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
      // Floating Action Button to add a new project.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProjectPage(
                firstName: firstName,
                lastName: lastName,
                email: email,
              ),
            ),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
