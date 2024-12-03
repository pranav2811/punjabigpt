import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:punjabigpt/screens/loginpage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _chatHistory = [];
  String? _currentChatTitle;
  String _selectedModel = 'gemma 2 9b';
  final List<String> _models = ['gemma 2 9b', 'llama 3', 'Sarvam - 1'];
  String? _extractedText;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _extractTextFromFile(String filePath) async {
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final recognizedText = await textRecognizer.processImage(inputImage);

      setState(() {
        _extractedText = recognizedText.text;
      });
    } catch (e) {
      print("Failed to extract text: $e");
    } finally {
      textRecognizer.close();
    }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty && _extractedText == null) return;

    String userMessage = _controller.text.isNotEmpty ? _controller.text : '';

    setState(() {
      if (_extractedText != null) {
        _messages.add({
          "role": "user",
          "message": "Attached file processed",
          "fileContent": _extractedText,
        });
      } else {
        _messages.add({"role": "user", "message": userMessage});
      }
      _controller.clear();
      _extractedText = null;
    });

    if (_currentChatTitle == "New Chat") {
      setState(() {
        _currentChatTitle = _getFirstFiveWords(userMessage);
        int chatIndex =
            _chatHistory.indexWhere((chat) => chat['title'] == "New Chat");
        if (chatIndex != -1) {
          _chatHistory[chatIndex]['title'] = _currentChatTitle!;
        }
      });
    }

    String url = "https://your-api-url-for-rag-pipeline";

    var response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "prompt": _extractedText ?? userMessage,
        "model": _selectedModel,
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

  Future<void> _attachFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single != null) {
      String fileName = result.files.single.name;
      String? filePath = result.files.single.path;

      if (filePath != null) {
        setState(() {
          _messages.add({
            "role": "user",
            "message": "Attached file: $fileName",
            "filePath": filePath,
          });
        });

        await _extractTextFromFile(filePath);
      } else {
        print("File path is null.");
      }
    } else {
      print("No file selected.");
    }
  }

  void _saveChatToHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not authenticated. Cannot save chat.");
      return;
    }

    if (_messages.isNotEmpty && _currentChatTitle != null) {
      _chatHistory.add({
        "title": _currentChatTitle!,
        "messages": jsonEncode(_messages),
      });

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('chats')
            .doc(_currentChatTitle)
            .set({"messages": jsonEncode(_messages)});
        print("Chat history saved to Firestore.");
      } catch (e) {
        print("Failed to save chat history: $e");
      }

      _messages.clear();
      _currentChatTitle = null;
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
            "title": doc.id,
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
    _saveChatToHistory();

    setState(() {
      _messages.clear();
      _currentChatTitle = "New Chat";
      _chatHistory.add({
        "title": _currentChatTitle!,
        "messages": jsonEncode([]),
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

  Widget _buildMessage(Map<String, dynamic> message) {
    bool isUserMessage = message['role'] == 'user';
    String displayMessage = message['message'] ?? '';

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color:
              isUserMessage ? const Color(0xFF343541) : const Color(0xFF444654),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message['filePath'] != null)
              const Icon(Icons.insert_drive_file, color: Colors.white),
            if (message['filePath'] != null) const SizedBox(width: 8.0),
            Text(
              displayMessage,
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
            ),
          ],
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
          title: Text(
            _chatHistory[index]['title']!,
            style: const TextStyle(color: Colors.white),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete') {
                _deleteChat(index);
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                    value: 'delete', child: Text('Delete Chat')),
              ];
            },
          ),
          onTap: () {
            Navigator.pop(context);
            setState(() {
              _messages.clear();
              _messages.addAll(
                (jsonDecode(_chatHistory[index]['messages']!) as List<dynamic>)
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList(),
              );
              _currentChatTitle = _chatHistory[index]['title'];
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
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedModel,
            dropdownColor: const Color(0xFF343541),
            items: _models.map((model) {
              return DropdownMenuItem(value: model, child: Text(model));
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedModel = newValue!;
              });
            },
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF202123),
          child: Column(
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
                    ListTile(
                      leading: const Icon(Icons.add, color: Colors.white),
                      title: const Text('New Chat',
                          style: TextStyle(color: Colors.white)),
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
                  onPressed: _attachFile,
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
