import 'package:flutter/material.dart';

class ProjectDisplayPage extends StatelessWidget {
  final Map<String, dynamic> projectData;

  const ProjectDisplayPage({Key? key, required this.projectData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract project data
    final String name = projectData['name'] ?? 'No Name';
    final String description = projectData['description'] ?? 'No Description';
    final String projectType = projectData['projectType'] ?? 'N/A';
    final List<dynamic>? languagesList = projectData['programmingLanguages'];
    final String programmingLanguages = languagesList != null
        ? languagesList.join(', ')
        : 'N/A';
    final String githubLink = projectData['githubLink'] ?? 'N/A';
    final String rapportUrl = projectData['rapportUrl'] ?? '';
    final Map<String, dynamic> submitter =
    projectData['submitter'] is Map<String, dynamic>
        ? projectData['submitter']
        : {};
    final String submitterName =
    "${submitter['firstName'] ?? ''} ${submitter['lastName'] ?? ''}".trim();
    final String submitterEmail = submitter['email'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Details"),
        backgroundColor: Colors.deepPurple,
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
          child: Card(
            color: Colors.white.withOpacity(0.92),
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Icon(Icons.description, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        "Description",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const Divider(height: 30, thickness: 1),
                  Row(
                    children: const [
                      Icon(Icons.category, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        "Project Type",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    projectType,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const Divider(height: 30, thickness: 1),
                  Row(
                    children: const [
                      Icon(Icons.code, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        "Languages",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    programmingLanguages,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const Divider(height: 30, thickness: 1),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.link, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text(
                        "Github Link",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // Optionally open the github link
                    },
                    child: Text(
                      githubLink,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Divider(height: 30, thickness: 1),
                  rapportUrl.isNotEmpty
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.picture_as_pdf,
                              color: Colors.deepPurple),
                          SizedBox(width: 8),
                          Text(
                            "Rapport",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // Optionally, implement PDF preview or launch URL.
                        },
                        child: Text(
                          rapportUrl,
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  )
                      : const Text("No Rapport Uploaded",
                      style: TextStyle(fontSize: 16)),
                  const Divider(height: 30, thickness: 1),
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
        ),
      ),
    );
  }
}
