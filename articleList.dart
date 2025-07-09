import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'articleDetails.dart';
import '/widgets/appBar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArticleListScreen extends StatefulWidget {
  @override
  _ArticleListScreenState createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  // Firestore collection reference
  final CollectionReference _articlesCollection =
      FirebaseFirestore.instance.collection('articles');

  // Method to filter the articles based on the search query
  void _filterArticles(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    bool isAdmin = _isUserAuthorized();

    return Scaffold(
      appBar: buildAppBar(context, 'Articles'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Admin Add Article Button
            if (isAdmin)
              ElevatedButton.icon(
                onPressed: () => _showAddArticleDialog(context),
                icon: Icon(Icons.add),
                label: Text('Add Article'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            SizedBox(height: 20),

            // Search bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search...',
                  icon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  _filterArticles(value); // Filter articles as the user types
                },
              ),
            ),
            SizedBox(height: 20),

            // List of Articles
            Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('articles').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading articles'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                List<Map<String, String>> allArticles = [];

                snapshot.data?.docs.forEach((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                String articleId = doc.id; // Use document ID as the article ID

                allArticles.add({
                  'articleId': articleId,
                  'title': data['title'] ?? 'No title available',
                  'date': data['date'] ?? 'No date available',
                  'description': data['description'] ?? 'No description available',
                  'videoUrl': data['videoUrl'] ?? '',
                });
              });

                return ListView.builder(
                  itemCount: allArticles.length,
                  itemBuilder: (context, index) {
                    final article = allArticles[index];
                    return _buildArticleTile(
                      context,
                      article['articleId']!, // Ensure articleId is being used
                      article['title']!,
                      article['date']!,
                      article['description']!,
                      article['videoUrl'] ?? '',
                    );
                  },
                );
              },
            ),
          ),
          ],
        ),
      ),
    );
  }

  // Method to build each article tile
  Widget _buildArticleTile(BuildContext context, String articleId, String title,
    String date, String description, String videoUrl) {
  return ListTile(
    title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text(date),
    onTap: () {
      Navigator.pushNamed(
        context,
        '/articleDetails',
        arguments: {
          'articleId': articleId,
          'title': title,
          'description': description,
          'date': date,
          'videoUrl': videoUrl,
        },
      );
    },
  );
}




  bool _isUserAuthorized() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.email == 'info@podc.org.au';
  }

  Future<void> _showAddArticleDialog(BuildContext context) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController videoUrlController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Article'),
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
                  // Save article to Firestore
                  _articlesCollection.add({
                    'title': titleController.text,
                    'date': DateTime.now().toLocal().toString().split(' ')[0],
                    'description': descriptionController.text,
                    'videoUrl': videoUrlController.text,
                  }).then((_) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Article added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }).catchError((error) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add article: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }
}
