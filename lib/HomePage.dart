import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // Replace with your login page file if needed.
import 'package:shared_preferences/shared_preferences.dart';
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

  void _disconnect(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear stored login data
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

              // Responsive Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount;
                  double cardHeight;
                  double cardWidth;

                  if (constraints.maxWidth < 600) {
                    // Mobile: 2 columns, taller cards
                    crossAxisCount = 2;
                    cardHeight = 120;
                    cardWidth = 140;
                  } else if (constraints.maxWidth < 1024) {
                    // Tablet: 3 columns, medium-sized cards
                    crossAxisCount = 3;
                    cardHeight = 100;
                    cardWidth = 160;
                  } else {
                    // Desktop: 4 columns, smaller cards
                    crossAxisCount = 4;
                    cardHeight = 80;
                    cardWidth = 180;
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
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      final projectNumber = index + 1;
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        elevation: 4,
                        child: SizedBox(
                          height: cardHeight,
                          width: cardWidth,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder,
                                size: 40,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Project $projectNumber",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
