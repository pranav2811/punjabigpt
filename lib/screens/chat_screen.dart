import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:punjabigpt/screens/loginpage.dart'; // Import LoginPage

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final List<Map<String, String>> _chatHistory = [];
  String? _currentChatTitle; // Track the current chat title

  @override
  void initState() {
    super.initState();
    _loadChatHistory(); // Load chat history on initialization
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    String userMessage = _controller.text;

    setState(() {
      _messages.add({"role": "user", "message": userMessage});
      _controller.clear();
    });

    // Send the message to the server and get a response
    var url =
        'https://5c00-34-125-215-19.ngrok-free.app/predict'; // Replace with your actual API URL
    var response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"prompt": userMessage}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        _messages.add({"role": "bot", "message": data['response']});
      });

      // Update current chat title if it's the first message in the chat
      if (_currentChatTitle == null) {
        _currentChatTitle = _getFirstFiveWords(userMessage);
      }
    } else {
      setState(() {
        _messages.add({
          "role": "bot",
          "message": "Error: Could not connect to the server."
        });
      });
    }
  }

  void _saveChatToHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not authenticated. Cannot save chat.");
      return;
    }

    if (_messages.isNotEmpty && _currentChatTitle != null) {
      // Add to local chat history
      _chatHistory.add({
        "title": _currentChatTitle!,
        "messages": jsonEncode(_messages),
      });

      // Save each chat as a separate field in the user's collection
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('chats')
            .doc(_currentChatTitle) // Use chat title as the document ID
            .set({
          "messages": jsonEncode(_messages),
        });
        print("Chat history saved to Firestore in user-specific collection.");
      } catch (e) {
        print("Failed to save chat history: $e");
      }

      _messages.clear(); // Clear current chat
      _currentChatTitle = null; // Reset current chat title
      setState(() {});
    }
  }

  void _loadChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not authenticated. Cannot load chat.");
      return;
    }

    try {
      var chatDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .get();

      setState(() {
        _chatHistory.clear();
        chatDocs.docs.forEach((doc) {
          _chatHistory.add({
            "title": doc.id, // Document ID is the chat title
            "messages": doc.data()['messages'],
          });
        });
        print("Chat history loaded from Firestore.");
      });
    } catch (e) {
      print("Failed to load chat history: $e");
    }
  }

  void _startNewChat() {
    _saveChatToHistory();
    Navigator.pop(context); // Close the drawer
    setState(() {
      _messages.clear();
      _currentChatTitle = null; // Reset current chat title for a new chat
    });
  }

  void _deleteChat(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not authenticated. Cannot delete chat.");
      return;
    }

    try {
      // Delete the chat from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(_chatHistory[index]['title']!)
          .delete();

      setState(() {
        _chatHistory.removeAt(index);
      });
      print("Chat deleted from Firestore and local history.");
    } catch (e) {
      print("Failed to delete chat: $e");
    }
  }

  String _getFirstFiveWords(String message) {
    List<String> words = message.split(' ');
    if (words.length > 5) {
      return words.take(5).join(' ') + '...';
    } else {
      return message;
    }
  }

  Widget _buildMessage(Map<String, String> message) {
    bool isUserMessage = message['role'] == 'user';
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUserMessage ? Color(0xFF343541) : Color(0xFF444654),
          borderRadius: BorderRadius.circular(20.0), // Rounded rectangle
        ),
        child: Text(
          message['message']!,
          style: TextStyle(color: Colors.white, fontSize: 16.0),
        ),
      ),
    );
  }

  Widget _buildChatHistory() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _chatHistory.length,
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.0), // Adjust padding
          title: Text(
            _chatHistory[index]['title']!,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete') {
                _deleteChat(index);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Chat'),
                ),
              ];
            },
          ),
          onTap: () {
            Navigator.pop(context); // Close the drawer
            setState(() {
              _messages.clear();
              _messages.addAll(
                (jsonDecode(_chatHistory[index]['messages']!) as List<dynamic>)
                    .map((e) => Map<String, String>.from(e))
                    .toList(),
              );
              _currentChatTitle =
                  _chatHistory[index]['title']; // Set current chat title
            });
          },
        );
      },
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () async {
                _saveChatToHistory(); // Save the current chat before logout
                Navigator.of(context).pop(); // Close the dialog
                await FirebaseAuth.instance.signOut();
                Future.delayed(Duration(milliseconds: 100), () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF202123),
      appBar: AppBar(
        title: Text('Punjabi LLM'),
        backgroundColor: Color(0xFF343541),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert), // Three dot vertical menu icon
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutConfirmationDialog(); // Show confirmation dialog
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ];
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Color(0xFF202123),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF343541)),
                margin: EdgeInsets.zero,
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat History',
                      style: TextStyle(fontSize: 24.0, color: Colors.white),
                    ),
                    SizedBox(height: 10.0),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF444654),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 6.0),
                        leading: Icon(Icons.add, color: Colors.white),
                        title: Text('New Chat',
                            style: TextStyle(color: Colors.white)),
                        onTap: _startNewChat,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _chatHistory.isEmpty
                      ? Center(
                          child: Text('No chat history available',
                              style: TextStyle(color: Colors.white)))
                      : _buildChatHistory(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Color(0xFF00A67E)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
