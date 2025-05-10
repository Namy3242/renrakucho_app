import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../post/view/post_list_screen.dart';
import '../../post/view/post_create_screen.dart'; // 追加

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ログイン中のユーザーID: ${user?.uid ?? "不明"}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostListScreen()),
                );
              },
              child: const Text('投稿一覧を見る'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PostCreateScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
// This screen serves as the main screen after login, displaying the user's ID and a button to view posts.
// The floating action button allows the user to create a new post.