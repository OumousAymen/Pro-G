final List<String> _inappropriateWords = [
  'badword1',
  'inappropriate2',
  'offensive3',
  // Add more as needed
];

/// Checks if the project name is inappropriate.
/// Returns `true` if inappropriate, `false` otherwise.
bool isInappropriateProjectName(String name) {
  final lowerName = name.toLowerCase();

  for (final word in _inappropriateWords) {
    if (lowerName.contains(word)) {
      return true;
    }
  }
  return false;
}

/// Checks if the given GitHub link is valid.
/// Accepts both profile and repository links.
/// Examples of valid links:
///   - https://github.com/username
///   - https://github.com/username/repository
bool isValidGithubLink(String link) {
  final githubRegex = RegExp(
    r'^https:\/\/github\.com\/[A-Za-z0-9_.-]+(\/[A-Za-z0-9_.-]+)?\/?$',
  );
  return githubRegex.hasMatch(link.trim());
}
