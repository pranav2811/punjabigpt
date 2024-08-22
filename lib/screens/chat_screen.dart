import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final List<Map<String, String>> _chatHistory = [];

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    String userMessage = _controller.text;

    setState(() {
      _messages.add({"role": "user", "message": userMessage});
      _controller.clear();
    });

    // Send the message to the server and get a response
    var url =
        'https://81bf-35-229-71-34.ngrok-free.app/predict'; // Replace with your actual API URL
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
    } else {
      setState(() {
        _messages.add({
          "role": "bot",
          "message": "Error: Could not connect to the server."
        });
      });
    }
  }

  void _saveChatToHistory() {
    if (_messages.isNotEmpty) {
      String firstMessage = _messages.first['message']!;
      String chatTitle = _getFirstFiveWords(firstMessage);

      _chatHistory.add({
        "title": chatTitle,
        "messages": jsonEncode(_messages),
      });

      _messages.clear(); // Clear current chat
      setState(() {});
    }
  }

  void _startNewChat() {
    _saveChatToHistory();
    Navigator.pop(context); // Close the drawer
    setState(() {
      _messages.clear();
    });
  }

  void _deleteChat(int index) {
    setState(() {
      _chatHistory.removeAt(index);
    });
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
            });
          },
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
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveChatToHistory,
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
                    style: TextStyle(color: Colors.white),
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
