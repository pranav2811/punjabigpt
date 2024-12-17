import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'model_selection_screen.dart';
import 'package:http_parser/http_parser.dart';

class ChatScreen extends StatefulWidget {
  final String serverUrl;
  final bool isRagModel;

  const ChatScreen({Key? key, required this.serverUrl, this.isRagModel = false})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, String>> _chatHistory = [];
  String? _currentChatTitle;
  String? _attachedFileName;
  String? _attachedFilePath;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty && _attachedFilePath == null) return;

    String userMessage = _controller.text;

    // Check if a file is attached
    bool isFileAttached = _attachedFilePath != null;

    if (isFileAttached) {
      // Use multipart/form-data when a file is attached
      var request = http.MultipartRequest('POST', Uri.parse(widget.serverUrl));
      request.fields['prompt'] = userMessage;

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _attachedFilePath!,
          contentType:
              MediaType('image', 'jpeg'), // Adjust content type as needed
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = jsonDecode(responseData);
        setState(() {
          _messages.add({"role": "bot", "message": data['response']});
        });
      } else {
        _handleError(response.statusCode, response.reasonPhrase);
      }
    } else {
      // Use JSON for text-only requests
      final payload = jsonEncode({"prompt": userMessage});

      final response = await http.post(
        Uri.parse(widget.serverUrl),
        headers: {"Content-Type": "application/json"},
        body: payload,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add({"role": "bot", "message": data['response']});
        });
      } else {
        _handleError(response.statusCode, response.reasonPhrase);
      }
    }

    _controller.clear();
    _attachedFileName = null;
    _attachedFilePath = null;
  }

  void _handleError(int statusCode, String? reason) {
    setState(() {
      _messages.add({
        "role": "bot",
        "message": "Error: $statusCode ${reason ?? 'Unknown error'}"
      });
    });
  }

  void _attachFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachedFileName = result.files.single.name;
        _attachedFilePath = result.files.single.path;
        _isUploading = true;
      });

      // Simulate a delay for file upload
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isUploading = false;
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
      // Always add to local history
      setState(() {
        if (!_chatHistory.any((chat) => chat['title'] == _currentChatTitle)) {
          _chatHistory.add({
            "title": _currentChatTitle!,
            "messages": jsonEncode(_messages),
          });
        } else {
          // Update the existing chat in local history
          int existingIndex = _chatHistory
              .indexWhere((chat) => chat['title'] == _currentChatTitle);
          _chatHistory[existingIndex]['messages'] = jsonEncode(_messages);
        }
      });

      // Save to Firestore
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
    // Save the current chat before starting a new one
    _saveChatToHistory();

    setState(() {
      // Clear messages and set new chat title
      _messages.clear();
      _currentChatTitle = "New Chat";

      // Add "New Chat" to the chat history only if it doesn't exist
      if (!_chatHistory.any((chat) => chat['title'] == _currentChatTitle)) {
        _chatHistory.add({
          "title": _currentChatTitle!,
          "messages": jsonEncode([]),
        });
      }
    });
  }

  void _deleteChat(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not authenticated. Cannot delete chat.");
      return;
    }

    try {
      String deletedChatTitle = _chatHistory[index]['title']!;

      // Delete the chat from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(deletedChatTitle)
          .delete();

      setState(() {
        _chatHistory.removeAt(index);

        // If the deleted chat is the currently open chat
        if (deletedChatTitle == _currentChatTitle) {
          // Clear the current chat and create a new one
          _messages.clear();
          _currentChatTitle = "New Chat";

          // Add "New Chat" to the chat history if it doesn't already exist
          if (!_chatHistory.any((chat) => chat['title'] == _currentChatTitle)) {
            _chatHistory.add({
              "title": _currentChatTitle!,
              "messages": jsonEncode([]),
            });
          }
        }
      });

      print("Chat deleted from Firestore.");
    } catch (e) {
      print("Failed to delete chat: $e");
    }
  }

  void _logout() {
    FirebaseAuth.instance.signOut();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _changeModel() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ModelSelectionScreen()),
    );
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
        if (widget.isRagModel)
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.white),
            onPressed: _attachFile,
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
                    Text(
                      _attachedFileName!,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
        title: Text(_currentChatTitle ?? "Chat"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              } else if (value == 'change_model') {
                _changeModel();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Log Out'),
                ),
                const PopupMenuItem(
                  value: 'change_model',
                  child: Text('Change Model'),
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
            child: _buildMessageInput(),
          ),
        ],
      ),
    );
  }
}
