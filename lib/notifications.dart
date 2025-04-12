import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'notification_utils.dart';
import 'theme.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    WidgetsBinding.instance.addObserver(
      this,
    ); // Ajouter un observateur pour les changements d’état
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Forcer un rafraîchissement lorsque l’application revient au premier plan
      setState(() {});
    }
  }

  Future<void> _clearAllNotifications() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      bool? confirm = await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "Confirmer",
                style: TextStyle(
                  fontFamily: 'SFPro',
                  color: AppTheme.darLockColor,
                ),
              ),
              content: Text(
                "Voulez-vous vraiment supprimer toutes les notifications ?",
                style: TextStyle(fontFamily: 'SFPro', color: Colors.grey[600]),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    "Annuler",
                    style: TextStyle(
                      fontFamily: 'SFPro',
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    "Supprimer",
                    style: TextStyle(fontFamily: 'SFPro', color: Colors.red),
                  ),
                ),
              ],
            ),
      );
      if (confirm != true) return;

      try {
        var collection = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications');
        var snapshots = await collection.get();
        for (var doc in snapshots.docs) {
          await doc.reference.delete();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Toutes les notifications ont été supprimées",
              style: TextStyle(fontFamily: 'SFPro'),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print("Erreur lors de la suppression : $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erreur lors de la suppression",
              style: TextStyle(fontFamily: 'SFPro'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String docId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(docId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Notification supprimée",
              style: TextStyle(fontFamily: 'SFPro'),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } catch (e) {
        print("Erreur lors de la suppression : $e");
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return "Aujourd'hui";
    } else if (notificationDate == today.subtract(Duration(days: 1))) {
      return "Hier";
    } else {
      return DateFormat('d MMM', 'fr_FR').format(date).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final background = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFEBEE)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.6,
              height: size.height * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE1BEE7).withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            right: -size.width * 0.1,
            child: Container(
              width: size.width * 0.5,
              height: size.height * 0.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFCCBC).withOpacity(0.05),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          background,
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Notifications",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darLockColor,
                          fontFamily: 'SFPro',
                        ),
                      ),
                      TextButton(
                        onPressed: _clearAllNotifications,
                        child: Text(
                          "Tout supprimer",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            fontFamily: 'SFPro',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseAuth.instance.currentUser != null
                            ? FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .collection('notifications')
                                .orderBy('timestamp', descending: true)
                                .snapshots()
                            : null,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Erreur : ${snapshot.error}",
                            style: TextStyle(
                              color: Colors.red,
                              fontFamily: 'SFPro',
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off,
                                size: 60,
                                color: Color(0xFFAB47BC),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Aucune notification",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppTheme.darLockColor,
                                  fontFamily: 'SFPro',
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      var notificationWithIds =
                          snapshot.data!.docs.map((doc) {
                            return {
                              'notification': NotificationItem.fromMap(
                                doc.data() as Map<String, dynamic>,
                              ),
                              'docId': doc.id,
                            };
                          }).toList();

                      Map<String, List<Map<String, dynamic>>>
                      groupedNotifications = {};
                      for (var item in notificationWithIds) {
                        NotificationItem notification =
                            item['notification'] as NotificationItem;
                        String dateKey = _formatDate(notification.timestamp);
                        if (!groupedNotifications.containsKey(dateKey)) {
                          groupedNotifications[dateKey] = [];
                        }
                        groupedNotifications[dateKey]!.add(item);
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: groupedNotifications.keys.length,
                        itemBuilder: (context, index) {
                          String dateKey = groupedNotifications.keys.elementAt(
                            index,
                          );
                          List<Map<String, dynamic>> notificationsForDate =
                              groupedNotifications[dateKey]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  dateKey,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF388E3C),
                                    fontFamily: 'SFPro',
                                  ),
                                ),
                              ),
                              AnimationLimiter(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: notificationsForDate.length,
                                  itemBuilder: (context, subIndex) {
                                    final item = notificationsForDate[subIndex];
                                    final notification =
                                        item['notification']
                                            as NotificationItem;
                                    final docId = item['docId'] as String;

                                    return AnimationConfiguration.staggeredList(
                                      position: subIndex,
                                      duration: Duration(milliseconds: 375),
                                      child: SlideAnimation(
                                        verticalOffset: 50.0,
                                        child: FadeInAnimation(
                                          child: Dismissible(
                                            key: Key(docId),
                                            background: Container(
                                              color: Colors.red,
                                              alignment: Alignment.centerRight,
                                              padding: EdgeInsets.only(
                                                right: 20,
                                              ),
                                              child: Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                              ),
                                            ),
                                            direction:
                                                DismissDirection.endToStart,
                                            onDismissed: (direction) {
                                              _deleteNotification(docId);
                                            },
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            NotificationDetailScreen(
                                                              notification:
                                                                  notification,
                                                            ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                margin: EdgeInsets.symmetric(
                                                  vertical: 2,
                                                ),
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFFFF3E0),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey
                                                          .withOpacity(0.1),
                                                      blurRadius: 10,
                                                      offset: Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 16,
                                                      backgroundColor: Color(
                                                        0xFFE1BEE7,
                                                      ).withOpacity(0.1),
                                                      child: Icon(
                                                        getIconForNotification(
                                                          notification.title,
                                                        ),
                                                        color: Color(
                                                          0xFFAB47BC,
                                                        ),
                                                        size: 20,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            notification.title,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  AppTheme
                                                                      .darLockColor,
                                                              fontFamily:
                                                                  'SFPro',
                                                            ),
                                                          ),
                                                          SizedBox(height: 2),
                                                          Text(
                                                            notification.body,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                              fontFamily:
                                                                  'SFPro',
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Text(
                                                      "${notification.timestamp.hour.toString().padLeft(2, '0')}:${notification.timestamp.minute.toString().padLeft(2, '0')}",
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Color(
                                                          0xFFFF7043,
                                                        ),
                                                        fontFamily: 'SFPro',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem notification;

  NotificationDetailScreen({required this.notification});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final background = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFEBEE)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.6,
              height: size.height * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE1BEE7).withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            right: -size.width * 0.1,
            child: Container(
              width: size.width * 0.5,
              height: size.height * 0.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFCCBC).withOpacity(0.05),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          background,
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFFAB47BC),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        "Détails de la notification",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darLockColor,
                          fontFamily: 'SFPro',
                        ),
                      ),
                      SizedBox(width: 48),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Color(0xFFFFF3E0),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Color(
                                  0xFFE1BEE7,
                                ).withOpacity(0.1),
                                child: Icon(
                                  getIconForNotification(notification.title),
                                  color: Color(0xFFAB47BC),
                                  size: 40,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darLockColor,
                                  fontFamily: 'SFPro',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Reçu le ${DateFormat('d MMM à HH:mm', 'fr_FR').format(notification.timestamp)}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFFF7043),
                                  fontFamily: 'SFPro',
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                notification.body,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontFamily: 'SFPro',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  "Fermer",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontFamily: 'SFPro',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
