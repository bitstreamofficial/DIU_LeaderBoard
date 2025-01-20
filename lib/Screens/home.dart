import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_first/Screens/profile.dart';
import 'package:flutter_first/services/connection_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final backgroundColor = const Color(0xFF1A1A1A);
  final cardColor = const Color(0xFF262626);
  final highlightColor = const Color(0xFF3C3C3C);
  final accentGreen = const Color(0xFF4CAF50);
  final selectedItemColor = const Color(0xFF2E4F3A);
  DateTime? lastPressedTime;
  final ConnectionHandler _connectionHandler = ConnectionHandler();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectionHandler.initialize(context);
    });
  }

  @override
  void dispose() {
    _connectionHandler.dispose();
    super.dispose();
  }
  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Exit App',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Do you want to exit the app?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'No',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            child: const Text(
              'Yes',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .doc(userId)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .where('dept_batch', isEqualTo: userData['dept_batch'])
                    .orderBy('cgpa', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final students = snapshot.data!.docs;
                  return Stack(
                    children: [
                      CustomScrollView(
                        slivers: [
                          // App Bar with Title and Department Info
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'DIU Leaderboard',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${userData['dept_batch'] ?? 'Unknown Department'}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Top 3 Podium
                          if (students.length >= 3)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: SizedBox(
                                  height: 200,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(child: _buildPodiumItem(students[1], 2)),
                                      Expanded(
                                          flex: 2, child: _buildPodiumItem(students[0], 1)),
                                      Expanded(child: _buildPodiumItem(students[2], 3)),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 20),
                          ),

                          // Remaining Rankings
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final studentDoc = students[index + 3];
                                final isCurrentUser = 
                                    studentDoc.id == FirebaseAuth.instance.currentUser?.uid;
                                return _buildListItem(studentDoc, index + 4, isCurrentUser);
                              },
                              childCount: students.length > 3 ? students.length - 3 : 0,
                            ),
                          ),
                        ],
                      ),
                      // Profile Icon positioned in top right
                      // Positioned(
                      //   top: 20,
                      //   right: 20,
                      //   child: IconButton(
                      //     icon: const Icon(
                      //       Icons.account_circle,
                      //       color: Colors.white,
                      //       size: 30,
                      //     ),
                      //     onPressed: () {
                      //       Navigator.of(context).push(
                      //         MaterialPageRoute(
                      //           builder: (context) => const ProfilePage(),
                      //         ),
                      //       );
                      //     },
                      //   ),
                      // ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumItem(DocumentSnapshot doc, int rank) {
    final student = doc.data() as Map<String, dynamic>;
    final showMe = student['showMe'] ?? true;
    final name = showMe ? (student['name'] ?? 'Unknown') : 'Anonymous';
    final cgpa = student['cgpa'].toStringAsFixed(2);

    Color getMedalColor(int rank) {
      switch (rank) {
        case 1:
          return const Color(0xFFFFD700); // Gold
        case 2:
          return const Color(0xFFC0C0C0); // Silver
        case 3:
          return const Color(0xFFCD7F32); // Bronze
        default:
          return Colors.grey[400]!;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (rank == 1)
          Transform.translate(
            offset: const Offset(0, 10),
            child: Image.asset(
              'assets/crown.png',
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 40 : 30,
              backgroundColor: getMedalColor(rank),
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: rank == 1 ? 24 : 20,
                ),
              ),
            ),
            if (rank <= 3)
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey[600]!,
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            color: Colors.white,
            fontSize: rank == 1 ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          cgpa,
          style: TextStyle(
            color: getMedalColor(rank),
            fontSize: rank == 1 ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(DocumentSnapshot doc, int rank, bool isCurrentUser) {
    final student = doc.data() as Map<String, dynamic>;
    final showMe = student['showMe'] ?? true;
    final name = showMe ? (student['name'] ?? 'Unknown') : 'Anonymous';
    final cgpa = student['cgpa'].toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isCurrentUser ? selectedItemColor : cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[800],
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            cgpa,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}