import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:punjabigpt/screens/loginpage.dart'; // Import LoginPage
import 'package:file_picker/file_picker.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final List<Map<String, String>> _chatHistory = [];
  String? _currentChatTitle; // Track the current chat title

  // Added variables for model selection
  String _selectedModel = 'gemma 2 9b';
  final List<String> _models = ['gemma 2 9b', 'llama 3', 'Sarvam - 1'];

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

    // Dynamically update the chat title if it's the first message
    if (_currentChatTitle == "New Chat") {
      setState(() {
        _currentChatTitle = _getFirstFiveWords(userMessage);

        // Update the title in the sidebar chat history
        int chatIndex =
            _chatHistory.indexWhere((chat) => chat['title'] == "New Chat");
        if (chatIndex != -1) {
          _chatHistory[chatIndex]['title'] = _currentChatTitle!;
        }
      });
    }

    // Select the appropriate API URL based on the selected model
    String url;
    switch (_selectedModel) {
      case 'gemma 2 9b':
        url =
            "https://4d88-35-186-154-94.ngrok-free.app/predict"; // Replace with actual API URL
        break;
      case 'llama 3':
        url =
            "https://4d88-35-186-154-94.ngrok-free.app/predict"; // Replace with actual API URL
        break;
      case 'Sarvam - 1':
        url =
            "https://4d88-35-186-154-94.ngrok-free.app/predict"; // Replace with actual API URL
        break;
      default:
        url =
            "https://4d88-35-186-154-94.ngrok-free.app/predict"; // Fallback URL
        break;
    }

    // Send the message to the server and get a response
    var response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "prompt": userMessage,
        "model": _selectedModel, // Include selected model
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        _messages.add({"role": "bot", "message": data['response']});
      });
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
        for (var doc in chatDocs.docs) {
          _chatHistory.add({
            "title": doc.id, // Document ID is the chat title
            "messages": doc.data()['messages'],
          });
        }
        print("Chat history loaded from Firestore.");
      });
    } catch (e) {
      print("Failed to load chat history: $e");
    }
  }

  void _startNewChat() {
    _saveChatToHistory(); // Save the current chat before starting a new one

    // Create a new chat entry in the local chat history
    setState(() {
      _messages.clear(); // Clear the current chat messages
      _currentChatTitle = "New Chat"; // Set default title for the new chat

      // Add the new chat to the sidebar immediately
      _chatHistory.add({
        "title": _currentChatTitle!,
        "messages": jsonEncode([]), // Empty chat initially
      });
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
      return '${words.take(5).join(' ')}...';
    } else {
      return message;
    }
  }

  Widget _buildMessage(Map<String, String> message) {
    bool isUserMessage = message['role'] == 'user';
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color:
              isUserMessage ? const Color(0xFF343541) : const Color(0xFF444654),
          borderRadius: BorderRadius.circular(20.0), // Rounded rectangle
        ),
        child: Text(
          message['message']!,
          style: const TextStyle(color: Colors.white, fontSize: 16.0),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
          title: Text(
            _chatHistory[index]['title']!,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete') {
                _deleteChat(index);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
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
              _currentChatTitle = _chatHistory[index]['title']; // Update title
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202123),
      appBar: AppBar(
        backgroundColor: const Color(0xFF343541),
        centerTitle: true,
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedModel,
            dropdownColor: const Color(0xFF343541),
            style: const TextStyle(color: Colors.white),
            iconEnabledColor: Colors.white,
            items: _models.map((String model) {
              return DropdownMenuItem<String>(
                value: model,
                child: Text(model),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedModel = newValue!;
              });
            },
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginPage()));
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
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
          color: const Color(0xFF202123),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF343541)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chat History',
                      style: TextStyle(fontSize: 24.0, color: Colors.white),
                    ),
                    const SizedBox(height: 10.0),
                    ListTile(
                      leading: const Icon(Icons.add, color: Colors.white),
                      title: const Text(
                        'New Chat',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: _startNewChat,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _chatHistory.isEmpty
                    ? const Center(
                        child: Text(
                          'No chat history available',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : _buildChatHistory(),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () async {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles();
                    if (result != null && result.files.single != null) {
                      String fileName = result.files.single.name;
                      String? filePath = result.files.single.path;

                      setState(() {
                        // Add the attached file to messages or handle it as needed
                        _messages.add({
                          "role": "user",
                          "message": "Attached file: $fileName"
                        });
                      });

                      print("File selected: $filePath");
                    } else {
                      print("No file selected.");
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Enter your message...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00A67E)),
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
