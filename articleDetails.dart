import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '/widgets/appBar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArticleDetailsScreen extends StatefulWidget {
  final String articleId;
  final String title;
  final String description;
  final String videoUrl;

  ArticleDetailsScreen({
    required this.articleId,
    required this.title,
    required this.description,
    required this.videoUrl,
  });

  @override
  _ArticleDetailsScreenState createState() => _ArticleDetailsScreenState();
}

class _ArticleDetailsScreenState extends State<ArticleDetailsScreen> {
  YoutubePlayerController? _youtubePlayerController;

  late String title;
  late String description;
  late String videoUrl;

  @override
  void initState() {
    super.initState();
    title = widget.title;
    description = widget.description;
    videoUrl = widget.videoUrl;

    // Initialize YouTube Player Controller with dynamic video ID
    if (videoUrl.isNotEmpty) {
      String? videoId = YoutubePlayerController.convertUrlToId(videoUrl);
      if (videoId != null) {
        _youtubePlayerController = YoutubePlayerController(
          initialVideoId: videoId,
          params: YoutubePlayerParams(
            autoPlay: false,
            mute: false,
            showControls: true,
            showFullscreenButton: true,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _youtubePlayerController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Articles'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  description,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // AUSLAN Translation Video Section
            if (_youtubePlayerController != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayerIFrame(
                  controller: _youtubePlayerController!,
                ),
              )
            else
              Container(
                height: 100,
                color: Colors.black12,
                child: Center(
                  child: Text(
                    'No Translation Available',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Edit and Delete Article Buttons (only visible for authorized user)
            if (_isUserAuthorized())
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _showEditArticleDialog(context);
                      },
                      child: Text('Edit Article'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        _showDeleteConfirmationDialog();
                      },
                      child: Text('Delete Article'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            if (_youtubePlayerController?.value.isFullScreen != true)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFooterButton(context, 'Back', Icons.arrow_back),
                  _buildFooterButton(context, 'Home', Icons.home),
                ],
              ),
          ],
        ),
      ),
    );
  }

  bool _isUserAuthorized() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.email == 'info@podc.org.au';
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Article'),
          content: Text('Are you sure you want to delete this article?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteArticle();
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteArticle() {
    FirebaseFirestore.instance
        .collection('articles')
        .doc(widget.articleId)
        .delete()
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Article deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Navigate back to the list of articles
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete article: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _showEditArticleDialog(BuildContext context) {
    final TextEditingController titleController =
        TextEditingController(text: title);
    final TextEditingController descriptionController =
        TextEditingController(text: description);
    final TextEditingController videoUrlController =
        TextEditingController(text: videoUrl);

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Article'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                const Text('Title:'),
                TextField(controller: titleController),
                const SizedBox(height: 8),
                const Text('Description:'),
                TextField(controller: descriptionController, maxLines: 3),
                const SizedBox(height: 8),
                const Text('YouTube Video URL (optional):'),
                TextField(controller: videoUrlController),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text('Submit'),
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  _editArticle(
                    titleController.text,
                    descriptionController.text,
                    videoUrlController.text,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _editArticle(String newTitle, String newDescription, String newVideoUrl) {
    FirebaseFirestore.instance.collection('articles').doc(widget.articleId).update({
      'title': newTitle,
      'description': newDescription,
      'videoUrl': newVideoUrl,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Article updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        title = newTitle;
        description = newDescription;
        videoUrl = newVideoUrl;

        // Update YouTube player if video URL changed
        if (newVideoUrl.isNotEmpty) {
          String? videoId = YoutubePlayerController.convertUrlToId(newVideoUrl);
          if (videoId != null) {
            _youtubePlayerController?.load(videoId);
          }
        }
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update article: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  // Footer navigation buttons
  Widget _buildFooterButton(BuildContext context, String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {
        if (label == 'Back') {
          Navigator.pop(context);
        } else if (label == 'Home') {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[300],
        foregroundColor: Colors.black,
      ),
    );
  }
}
