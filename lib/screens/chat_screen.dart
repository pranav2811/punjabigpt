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
  String? _attachedFileName;
  String? _attachedFilePath;
  bool _isUploading = false;

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
        _isUploading = false;
      });
    } catch (e) {
      print("Failed to extract text: $e");
    } finally {
      textRecognizer.close();
    }
  }

  Future<void> _attachFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single != null) {
      setState(() {
        _attachedFileName = result.files.single.name;
        _attachedFilePath = result.files.single.path;
        _isUploading = true;
      });

      if (_attachedFilePath != null) {
        await _extractTextFromFile(_attachedFilePath!);
      }
    } else {
      print("No file selected.");
    }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty && _attachedFilePath == null) return;

    String userMessage = _controller.text;

    setState(() {
      if (_attachedFilePath != null) {
        _messages.add({
          "role": "user",
          "message": userMessage,
          "fileName": _attachedFileName,
          "filePath": _attachedFilePath,
        });
      } else {
        _messages.add({"role": "user", "message": userMessage});
      }
      _controller.clear();
      _attachedFileName = null;
      _attachedFilePath = null;
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

    // Select the appropriate API URL based on the selected model
    String url;
    switch (_selectedModel) {
      case 'gemma 2 9b':
        url = "https://5c00-34-125-215-19.ngrok-free.app/predict";
        break;
      case 'llama 3':
        url = "https://5c00-34-125-215-19.ngrok-free.app/predict";
        break;
      case 'Sarvam - 1':
        url = "https://5c00-34-125-215-19.ngrok-free.app/predict";
        break;
      default:
        url = "https://5c00-34-125-215-19.ngrok-free.app/predict";
        break;
    }

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
    // Save the current chat to history if it exists
    if (_currentChatTitle != null && _messages.isNotEmpty) {
      _saveChatToHistory();
    }

    setState(() {
      // Clear messages for the new chat
      _messages.clear();

      // Create a unique title for the new chat
      _currentChatTitle = "New Chat ";

      // Add the new chat to the chat history
      _chatHistory.add({
        "title": _currentChatTitle!,
        "messages": jsonEncode([]), // Start with an empty chat
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

  Widget _buildMessageInput() {
    return Row(
      children: [
        IconButton(
          onPressed: _attachFile,
          icon: const Icon(Icons.attach_file, color: Colors.white),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_attachedFileName != null)
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: Colors.white),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _attachedFileName!,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isUploading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Enter your message...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send, color: Color(0xFF00A67E)),
          onPressed: _sendMessage,
        ),
      ],
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    bool isUserMessage = message['role'] == 'user';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message['fileName'] != null)
              Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.white),
                  const SizedBox(width: 8.0),
                  Text(
                    message['fileName'],
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            Text(
              message['message'] ?? '',
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
            child: _buildMessageInput(),
          ),
        ],
      ),
    );
  }
}
