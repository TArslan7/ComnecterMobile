
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class FriendCard extends StatefulWidget {
  final String username;
  final VoidCallback onSendRequest;

  FriendCard({required this.username, required this.onSendRequest});

  @override
  _FriendCardState createState() => _FriendCardState();
}

class _FriendCardState extends State<FriendCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    player.dispose();
    super.dispose();
  }

  void _handleRequest() {
    player.play(AssetSource('sounds/friend_request.mp3'));
    widget.onSendRequest();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Card(
        child: ListTile(
          title: Text(widget.username),
          trailing: IconButton(
            icon: Icon(Icons.person_add),
            onPressed: _handleRequest,
          ),
        ),
      ),
    );
  }
}
