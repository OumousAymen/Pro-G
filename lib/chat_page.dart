import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'secrets.dart';
import 'dart:math';


class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _messagesCollection;
  late GenerativeModel _model;
  //for animation
  bool _isLoading = false;
  late AnimationController _loadingController;
  final List<double> _dotOpacities = [0.2, 0.2, 0.2];
  // Add to _ChatPageState class
  late AnimationController _waveController;
  final List<Animation<double>> _dotAnimations = [];

  @override
  void initState() {
    super.initState();
    // Initial scroll to bottom after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: geminiApiKey);

    final user = _auth.currentUser;
    if (user != null) {
      _messagesCollection = _firestore
          .collection('chats')
          .doc(user.uid)
          .collection('messages');
    }

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    for (var i = 0; i < 3; i++) {
      _dotAnimations.add(Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _waveController,
          curve: Interval(i * 0.2, 1.0, curve: Curves.easeInOut),
        ),
      ));
    }
  }

  Widget _buildLoadingDot(int index) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Opacity(
          opacity: _dotAnimations[index].value,
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Add user message
      await _messagesCollection.add({
        'text': message,
        'isUser': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();

      // Get Gemini response
      final content = [Content.text(message)];
      final response = await _model.generateContent(content);

      // Add bot response
      await _messagesCollection.add({
        'text': response.text ?? 'I did not understand that.',
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await _messagesCollection.add({
        'text': 'Sorry, I encountered an error. Please try again.',
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } finally {
      setState(() => _isLoading = false);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Assistant'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesCollection.orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                // scroll to end
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  itemCount: messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator as the last item if loading
                    if (index >= messages.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildLoadingDot(0),
                              const SizedBox(width: 4),
                              _buildLoadingDot(1),
                              const SizedBox(width: 4),
                              _buildLoadingDot(2),
                            ],
                          ),
                        ),
                      );
                    }

                    final message = messages[index].data() as Map<String, dynamic>;
                    final isUser = message['isUser'] ?? false;

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.deepPurple : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message['text'],
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },

                );
                },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // animation widget



}
