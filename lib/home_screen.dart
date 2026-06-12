import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';
import 'labour_hiring.dart';
import 'rating_and_review.dart';
import 'login_screen.dart';
import 'splash_screen.dart';
import 'contractor_mode.dart';
import 'online_purchasing.dart';
import 'cost_estimation.dart';
import 'package:url_launcher/url_launcher.dart';
import '3d_viewer.dart';
import 'City_selection.dart';
import 'Help page.dart';
import 'privacy_policies_screen.dart';
import 'user_queries_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Notification Page.dart';
import 'payment_verification.dart';


enum NotificationType { email, company, interaction }

class MyNotification {
  final NotificationType type;
  final String id;
  final String title;
  final String user_id;
  final String message;
  final int timestamp; // Stored in milliseconds
  final String fromUser; // Who sent it (company/admin)
  final String toUser;   // Who should receive it
  final String userEmail;

  bool isRead;
  bool isReadLocal;

  MyNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.fromUser,
    required this.user_id,
    required this.toUser,
    required this.type,
    this.userEmail = '',
    this.isRead = false,
    bool? isReadLocal, // 🔹 optional parameter
  }) : isReadLocal = isReadLocal ?? isRead;

  factory MyNotification.fromMap(String id, Map data) {
    return MyNotification(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] ?? 0,
      fromUser: data['from_user'] ?? '',
      toUser: data['to_user'] ?? '',
      user_id: data['user_id'] ?? '',   // ✅ THIS LINE WAS MISSING
      type: data['type'] == 'email'
          ? NotificationType.email
          : NotificationType.company,
      isRead: data['is_read'] ?? false,
      userEmail: data['user_email'] ?? '',
    );
  }

}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryColor = const Color(0xFF0E0E1F);
  final Color accentColor = const Color(0xFF2A2D3E);
  final Color highlightColor = const Color(0xFFF4B400);
  final GlobalKey _bellKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  String selectedLanguage = 'English';
  String searchQuery = '';
  late TextEditingController _searchController;
  final ScrollController _notificationScrollController =
  ScrollController();
  bool isLoadingNotifications = false;

  late stt.SpeechToText _speech;
  bool isListening = false;
  List<MyNotification> emailResponses = [];
  List<MyNotification> paymentResponses = [];
  List<MyNotification> feedbackResponses = [];
  List<MyNotification> hiringResponses = [];


  @override
  void initState() {
    super.initState();
    fetchFeedbackResponses();
    fetchPaymentResponses();
    _searchController = TextEditingController(text: searchQuery);
    _speech = stt.SpeechToText();
  }
  @override
  void dispose() {
    _searchController.dispose();
    _notificationScrollController.dispose();
    super.dispose();
  }
  void removeNotification(String id) {
    setState(() {
      // Email
      emailResponses.removeWhere((n) => n.id == id);

      // Payment
      paymentResponses.removeWhere((n) => n.id == id);

      // Feedback
      feedbackResponses.removeWhere((n) => n.id == id);
    });
  }

  void _showNotificationsDropdown(BuildContext context, GlobalKey key) async {
    await fetchFeedbackResponses();
    final paymentResponses = await fetchPaymentResponses();
    emailResponses = await fetchEmailResponses();

    if (!mounted) return;




    final overlay = Overlay.of(context);
    if (overlay == null) return; // safety check
    final overlayBox = overlay.context.findRenderObject() as RenderBox;

    final buttonBox = key.currentContext!.findRenderObject() as RenderBox;
    final position = buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    const dropdownWidth = 320.0;
    double left = position.dx;
    final screenWidth = overlayBox.size.width;
    if (left + dropdownWidth > screenWidth) {
      left = screenWidth - dropdownWidth - 10;
    }

    final scrollController = ScrollController();

    _overlayEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: position.dy + buttonBox.size.height,
              width: dropdownWidth,
              child: Material(
                color: Colors.transparent,
                child: Card(
                  color: const Color(0xFF302F2F),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: SizedBox(
                    height: 360, // slightly taller for the new link
                    child: Scrollbar(
                      controller: scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(
                                "Email",
                                Icons.mail,
                                emailResponses, // email list
                              ),

                              _buildHeader(
                                "Company",
                                Icons.business,
                                [
                                  ...paymentResponses,
                                  ...feedbackResponses,
                                  ...hiringResponses, // ✅ added here
                                ]..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
                              ),


                              _buildHeader(
                                "Interaction",
                                Icons.thumb_up,
                                [], // empty list triggers your “You're up to date 🎉” message
                              ),


                              const SizedBox(height: 8),
                              const Divider(color: Colors.grey), // line above link
                              const SizedBox(height: 4),

                              // ✅ Mark all as read link
                              InkWell(
                                onTap: () async {
                                  // Local update
                                  for (var n in [...emailResponses, ...paymentResponses, ...feedbackResponses, ...hiringResponses]) {
                                    n.isReadLocal = true;
                                  }

                                  // Update Firebase for payment, feedback, hiring
                                  for (var n in [...paymentResponses, ...feedbackResponses, ...hiringResponses]) {
                                    await FirebaseDatabase.instance
                                        .ref('payment_responses/${n.id}') // for payments
                                        .update({'read': true});
                                  }

                                  setState(() {}); // refresh UI
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Mark all messages as read',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              )


                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

      ),
    );

    overlay.insert(_overlayEntry!);
  }

  Future<List<MyNotification>> fetchHiringResponses() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    List<MyNotification> temp = [];

    try {
      final snapshot =
      await FirebaseDatabase.instance.ref('user_notifications/$userId').get();

      if (snapshot.exists) {
        for (final entry in snapshot.children) {
          final data = Map<String, dynamic>.from(entry.value as Map);
          if (data['userId'] == userId &&
              (data['status'] == 'Accepted' || data['status'] == 'Rejected')) {
            temp.add(MyNotification(
              id: entry.key ?? '',
              title: "Hiring Request ${data['status']}",
              message: data['message'] ?? '',
              timestamp: data['createdAt'] ?? 0,
              fromUser: 'company',
              toUser: userId,
              user_id: userId,
              type: NotificationType.company,
              isRead: data['read'] ?? false,
              userEmail: FirebaseAuth.instance.currentUser?.email ?? '',
            ));
          }
        }
      }

      temp.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint("Error fetching hiring responses: $e");
    }

    return temp; // ✅ return the list
  }




  Future<List<MyNotification>> fetchEmailResponses() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    List<MyNotification> emailList = [];

    try {
      final snapshot =
      await FirebaseDatabase.instance.ref('email_responses').get();

      if (snapshot.exists) {
        for (final entry in snapshot.children) {
          final data = Map<String, dynamic>.from(entry.value as Map);

          // Only show emails for this user (or empty user_id if testing)
          if (data['user_id'] == userId || data['user_id'] == "") {
            emailList.add(MyNotification(
              id: entry.key ?? '',
              title: "Email",
              user_id: data['user_id'] ?? '',
              message: data['message'] ?? '',
              timestamp: data['timestamp'] ?? 0,
              type: NotificationType.email,
              isRead: data['status'] == "read",
              fromUser: "company",
              toUser: userId,
            ));
          }
        }
      }

      emailList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint("Error fetching email responses: $e");
    }

    return emailList;
  }





  Future<void> fetchFeedbackResponses() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    List<MyNotification> tempResponses = [];

    try {
      // 🔹 Read the entire feedback_responses node (nested structure)
      final feedbackSnapshot =
      await FirebaseDatabase.instance.ref('feedback_responses').get();

      if (feedbackSnapshot.exists) {
        // Iterate over top-level keys
        for (final feedbackEntry in feedbackSnapshot.children) {
          // Iterate over nested responses
          for (final responseEntry in feedbackEntry.children) {
            final responseData =
            Map<String, dynamic>.from(responseEntry.value as Map);

            // ✅ Filter by current user and sender = company
            if (responseData['userId'] == userId &&
                responseData['sender'] == 'company') {
              tempResponses.add(MyNotification(
                id: responseEntry.key ?? '',
                title: "Feedback Response",
                user_id: responseData['user_id'] ?? '',
                message: responseData['responseMessage'] ?? '',
                timestamp: responseData['responseTimestamp'] ?? 0,
                type: NotificationType.company,
                isRead: false,
                fromUser: 'company',
                toUser: userId,
              ));
            }
          }
        }
      }

      // Sort latest first
      tempResponses.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Update state
      if (mounted) {
        setState(() {
          feedbackResponses = tempResponses;
        });
      }
    } catch (e) {
      debugPrint("Error fetching feedback responses: $e");
    }
  }

  Future<List<MyNotification>> fetchPaymentResponses() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    List<MyNotification> paymentResponses = [];

    try {
      final paymentSnapshot =
      await FirebaseDatabase.instance.ref('payment_responses').get();

      if (paymentSnapshot.exists) {
        for (final paymentEntry in paymentSnapshot.children) {
          final data = Map<String, dynamic>.from(paymentEntry.value as Map);

          // Only include responses for the current user
          if (data['userId'] == userId) {
            paymentResponses.add(MyNotification(
              id: paymentEntry.key ?? '',
              title: "Payment Response",
              message: data['reason'] ?? '',
              timestamp: data['timestamp'] ?? 0,
              fromUser: 'company',
              user_id: data['userId'] ?? '',
              toUser: userId,
              type: NotificationType.company,
              isRead: data['read'] ?? false,
              isReadLocal: data['read'] ?? false, // ⚡ important
            ));
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching payment responses: $e");
    }

    // Sort latest first
    paymentResponses.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return paymentResponses;
  }





  final Map<String, Map<String, String>> localizedText = {
    'English': {
      'home': 'Home',
      'laborHiring': 'Labor Hiring',
      'costEstimation': 'Cost Estimation',
      'buyMaterials': 'Buy Materials',
      'userQueries': 'User Queries',
      '3d_viewer': '3D Viewer',
      'Help': 'Help & Guidance',
      'ratingReview': 'Rating & Review',
      'complaint': 'Raise a Complaint',
      'faq': 'FAQs',
      'privacy': 'Privacy Policies',
      'contractorMode': 'Contractor Mode',
      'supplierMode': 'Supplier Mode',
      'contactSupport': 'Contact Support',
      'logout': 'Logout',
      'coreEngine': 'Core Engine',
      'assistiveSuite': 'Assistive Suite',
      'viewAll': 'View All',
      'shoppingHint': 'What are you looking for?',
    },
    'Urdu': {
      'home': 'ہوم',
      'laborHiring': 'مزدور کی خدمات حاصل کریں',
      'costEstimation': 'لاگت کا تخمینہ',
      'buyMaterials': 'مواد خریدیں',
      'userQueries': 'صارف کے سوالات',
      '3d_viewer': 'تھری ڈی دیکھنے والا',
      'chatbotHelp': 'مدد اور رہنمائی',
      'ratingReview': 'درجہ بندی اور جائزہ',
      'complaint': 'شکایت درج کریں',
      'faq': 'عمومی سوالات',
      'privacy': 'رازداری کی پالیسیاں',
      'contractorMode': 'ٹھیکیدار موڈ',
      'supplierMode': 'سپلائر موڈ',
      'contactSupport': 'رابطہ معاونت',
      'logout': 'لاگ آؤٹ',
      'coreEngine': 'بنیادی انجن',
      'assistiveSuite': 'مددگار سوٹ',
      'viewAll': 'سب دیکھیں',
      'shoppingHint': 'آپ کیا خرید رہے ہیں؟',
    },
  };
  final List<Map<String, dynamic>> coreEngineFeatures = [
    {
      'icon': Icons.view_in_ar_rounded,
      'label': '3D Viewer',
      'screen': Meshy3DPage()
    },
    {
      'icon': Icons.attach_money,
      'label': 'Cost Estimation',
      'screen': CostEstimationPage()
    },
    {
      'icon': Icons.mark_unread_chat_alt,
      'label': 'Help & Guidance',
      'screen': ChatBot()
    },
  ];

  final List<Map<String, dynamic>> assistiveSuiteFeatures = [
    {'icon': Icons.build, 'label': 'Labor Hiring', 'screen': CitySelectionPage()},
    {
      'icon': Icons.shopping_bag_outlined,
      'label': 'Online Purchasing',
      'screen': OnlinePurchasingPage()
    },

    {
      'icon': Icons.star_outline,
      'label': 'User Feedback System',
      'screen': RatingAndReviewScreen()
    },
  ];

  @override
  Widget build(BuildContext context) {
    final t = localizedText[selectedLanguage]!;

    List<Map<String, dynamic>> filteredCore = coreEngineFeatures
        .where(
            (f) => f['label'].toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
    List<Map<String, dynamic>> filteredAssistive = assistiveSuiteFeatures
        .where(
            (f) => f['label'].toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: accentColor,
        elevation: 4,
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Expanded(child: _buildSearchBar(t)),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: selectedLanguage,
              dropdownColor: accentColor,
              underline: const SizedBox(),
              icon: const Icon(Icons.language, color: Colors.white),
              items: ['English', 'Urdu']
                  .map((lang) => DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang,
                            style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (lang) => setState(() => selectedLanguage = lang!),
            ),
            const SizedBox(width: 15),
            IconButton(
              key: _bellKey,
              icon: Stack(
                children: [
                  isLoadingNotifications
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                  ),
                  // Yellow dot if ANY unread exists
                  if (emailResponses.any((n) => !n.isReadLocal) ||
                      paymentResponses.any((n) => !n.isReadLocal) ||
                      feedbackResponses.any((n) => !n.isReadLocal) ||
                      hiringResponses.any((n) => !n.isReadLocal))
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: "Notifications",
              onPressed: () async {
                setState(() => isLoadingNotifications = true);

                // Fetch all notifications
                emailResponses = await fetchEmailResponses();
                paymentResponses = await fetchPaymentResponses();
                hiringResponses = await fetchHiringResponses();
                await fetchFeedbackResponses();

                setState(() => isLoadingNotifications = false);

                _showNotificationsDropdown(context, _bellKey);
              },
            ),



          ],
        ),
      ),
      drawer: _buildDrawer(context),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          _buildPromoBanner(),
          const SizedBox(height: 20),
          _buildSectionHeader(context, t['coreEngine']!, () {}),
          _buildGridModules(context, filteredCore),
          const SizedBox(height: 20),
          _buildSectionHeader(context, t['assistiveSuite']!, () {}),
          _buildGridModules(context, filteredAssistive),
        ],
      ),
    );
  }

  Widget _buildHeader(
      String title,
      IconData icon,
      List<MyNotification> list,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFC9993F), // 🟡 Yellow (logo style)
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: ThemeData().copyWith(
          dividerColor: Colors.transparent, // remove default divider
        ),
        child: ExpansionTile(
          initiallyExpanded: title == "Email",
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          title: Row(
            children: [
              Icon(icon, size: 18, color: Colors.white), // 🤍 icon
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white, // 🤍 text
                ),
              ),
            ],
          ),

          // ✅ ONLY THIS PART UPDATED
          children: title == "Interaction" && list.isEmpty
              ? const [
            SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  "You're up to date 🎉",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ]
              : list.isEmpty
              ? const [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: Text(
                "No messages",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ]
              : list
              .map(
                (note) => NotificationTile(
              note: note,
              onClear: () {
                removeNotification(note.id);
              },
            ),
          )
              .toList(),
        ),
      ),
    );
  }






  Widget _buildSearchBar(Map<String, String> t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: t['shoppingHint'],
                border: InputBorder.none,
              ),
              controller: _searchController,
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          AvatarGlow(
            animate: isListening,
            glowColor: Colors.blue,
            //glowShape: BoxShape.circle,
            duration: const Duration(milliseconds: 2000),
            repeat: true,
            //showTwoGlows: true, // optional, adds nicer effect
            child: IconButton(
              padding: EdgeInsets.zero, // 🔹 remove extra space
              constraints: const BoxConstraints(
                // 🔹 control size
                minWidth: 30,
                minHeight: 30,
              ),
              icon: const Icon(Icons.mic, color: Colors.blue, size: 15),
              onPressed: () async {
                if (!isListening) {
                  bool available = await _speech.initialize();
                  if (available) {
                    setState(() => isListening = true);
                    _speech.listen(onResult: (val) {
                      setState(() {
                        _searchController.text = val.recognizedWords;
                        searchQuery = val.recognizedWords;
                      });
                    });
                  }
                } else {
                  setState(() => isListening = false);
                  _speech.stop();
                }
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage('assets/logo.png'),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, void Function() onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: onViewAll,
          child: const Text('View All', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildGridModules(
      BuildContext context, List<Map<String, dynamic>> features) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: features.map((feature) {
        return Card(
          color: accentColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => feature['screen']));
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(feature['icon'], color: highlightColor, size: 34),
                  const SizedBox(height: 8),
                  Text(feature['label'],
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final t = localizedText[selectedLanguage]!;
    return Drawer(
      backgroundColor: primaryColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF4F46E5), accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.engineering, color: Colors.white, size: 48),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Welcome to Smart Construction & Labor Hub!',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          _drawerItem(
              context, Icons.home, t['home']!, () => Navigator.pop(context)),
          _drawerItem(
              context,
              Icons.build,
              t['laborHiring']!,
              () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => CitySelectionPage()))),
          _drawerItem(
              context,
              Icons.attach_money,
              t['costEstimation']!,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CostEstimationPage()))),
          _drawerItem(
              context,
              Icons.shopping_bag_outlined,
              t['buyMaterials']!,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => OnlinePurchasingPage()))),
          _drawerItem(
              context,
              Icons.view_in_ar,
              t['3d_viewer']!,
              () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => Meshy3DPage()))),
          _drawerItem(
              context,
              Icons.chat,
              t['Help']!,
              () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ChatBot()))),
          _drawerItem(
              context,
              Icons.star_outline,
              t['ratingReview']!,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => RatingAndReviewScreen()))),
          const Divider(color: Colors.white54),
          _drawerItem(context, Icons.copy_outlined, t['complaint']!, () {}),
          _drawerItem(context, Icons.format_quote_outlined, t['faq']!, () {}),
          _drawerItem(
              context,
              Icons.engineering,
              t['contractorMode']!,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ContractorMode()))),
          _drawerItem(
              context,
              Icons.engineering,
              t['privacy']!,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => PrivacyPoliciesScreen()))),
          _drawerItem(
              context,
              Icons.engineering,
              t['userQueries']!,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => UserQueriesPage()))),
          _drawerItem(context, Icons.local_shipping, t['supplierMode']!, () {}),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(t['contactSupport']!,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const ListTile(
            leading: Icon(Icons.contact_page_sharp, color: Colors.white),
            title: Text("smartconstruction@gmail.com",
                style: TextStyle(color: Colors.white)),
            subtitle: Text("+92 315 0700667",
                style: TextStyle(color: Colors.white70)),
          ),
          _drawerItem(
              context,
              Icons.exit_to_app,
              t['logout']!,
              () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          SplashScreen(nextPage: const LoginPage())))),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title,
      void Function() onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}



class NotificationTile extends StatefulWidget {
  final MyNotification note;
  final VoidCallback onClear;

  const NotificationTile({
    Key? key,
    required this.note,
    required this.onClear,
  }) : super(key: key);

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  bool showFullMessage = false;
  bool isSendingReply = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final ts = DateTime.fromMillisecondsSinceEpoch(note.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// TITLE + TIMESTAMP
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: note.isReadLocal
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "${ts.hour}:${ts.minute.toString().padLeft(2, '0')}\n${ts.day}/${ts.month}/${ts.year}",
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 8),

            /// MESSAGE
            Text(
              note.message,
              maxLines: showFullMessage ? null : 4,
              overflow: showFullMessage
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                color: Colors.black, // ✅ IMPORTANT
                fontWeight:
                note.isReadLocal ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            if (note.message.length > 120)
              GestureDetector(
                onTap: () =>
                    setState(() => showFullMessage = !showFullMessage),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    showFullMessage ? "Read less" : "Read more",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            /// ACTION BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [

                /// MARK AS READ
                TextButton(
                  onPressed: note.isReadLocal
                      ? null
                      : () async {
                    // All company-type notifications (payment, feedback, hiring) go here
                    final ref = note.type == NotificationType.email
                        ? FirebaseDatabase.instance.ref('email_responses/${note.id}')
                        : FirebaseDatabase.instance
                        .ref('user_notifications/${note.toUser}/${note.id}'); // payment/feedback/hiring

                    await ref.update(
                      note.type == NotificationType.email
                          ? {'status': 'read'} // for email
                          : {'isRead': true},  // for payment, feedback, hiring
                    );

                    if (!mounted) return;
                    setState(() => note.isReadLocal = true);
                  },
                  child: const Text("Mark as read"),
                ),


                /// REPLY (EMAIL ONLY)
                if (note.type == NotificationType.email)
                  TextButton(
                    onPressed: () => _openReplyDialog(context, note),
                    child: const Text("Reply"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openReplyDialog(BuildContext context, MyNotification note) {
    final TextEditingController replyController = TextEditingController();
    bool isSendingReplyDialog = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Reply to Email"),
          content: TextField(
            controller: replyController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "Type your reply here...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isSendingReplyDialog
                  ? null
                  : () async {
                final replyText = replyController.text.trim();
                if (replyText.isEmpty) return;

                // Update the dialog state
                setDialogState(() => isSendingReplyDialog = true);

                try {
                  await FirebaseDatabase.instance
                      .ref('email_replies')
                      .push()
                      .set({
                    'from_user': FirebaseAuth.instance.currentUser!.uid,
                    'to_email': '26116@students.riphah.edu.pk',
                    'message': replyText,
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  });

                  if (Navigator.canPop(dialogContext)) {
                    Navigator.pop(dialogContext);
                  }
                } catch (e) {
                  // Optionally show an error snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to send reply: $e")),
                  );
                  setDialogState(() => isSendingReplyDialog = false);
                }
              },
              child: isSendingReplyDialog
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text("Send"),
            ),
          ],
        ),
      ),
    );
  }

/// REPLY DIALOG → SAVES TO email_replies ONLY

}
