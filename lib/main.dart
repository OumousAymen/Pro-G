import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryout/signup.dart';
import 'firebase_options.dart';
import 'homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// AuthWrapper checks if user is remembered
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _firstName, _lastName, _email;

  @override
  void initState() {
    super.initState();
    _checkRememberMe();
  }

  Future<void> _checkRememberMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe) {
      _firstName = prefs.getString('firstName');
      _lastName = prefs.getString('lastName');
      _email = prefs.getString('email');
      setState(() {
        _isLoggedIn = true;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _isLoggedIn
        ? HomePage(firstName: _firstName!, lastName: _lastName!, email: _email!)
        : const MyHomePage(title: 'Login');
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      // Sign in with email and password.
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Reload the user to ensure the emailVerified flag is updated.
      User? user = userCredential.user;
      if (user != null) {
        await user.reload();
        user = FirebaseAuth.instance.currentUser;
        if (!user!.emailVerified) {
          _showError("Your email is not verified. Please check your inbox for the verification email.");
          await FirebaseAuth.instance.signOut();
          return;
        }
      }

      // Retrieve user data from Firestore.
      String uid = user!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Utilisateurs')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        String firstName = userDoc.get('firstName');
        String lastName = userDoc.get('lastName');
        String email = userDoc.get('email');

        if (_rememberMe) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('rememberMe', true);
          await prefs.setString('firstName', firstName);
          await prefs.setString('lastName', lastName);
          await prefs.setString('email', email);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              firstName: firstName,
              lastName: lastName,
              email: email,
            ),
          ),
        );
      } else {
        _showError("User data not found in Firestore.");
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "An authentication error occurred.");
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F1F8), Color(0xFFF4F1F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          hintText: "Enter your email",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          hintText: "Enter your password",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (bool? value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                          ),
                          const Text("Remember me"),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          elevation: 5,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text("Login"),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpPage()),
                          );
                        },
                        child: const Text(
                          "Don't have an account? Sign up",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
