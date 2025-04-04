import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/Screens/authentication_screen.dart';
import 'package:app/utils/api_client.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Add this import

class ProfileScreen extends StatefulWidget {
  final String userName;

  const ProfileScreen({super.key, required this.userName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingWallet = true;
  String _walletAddress = '';
  String _errorMessage = '';
  bool _hasError = false;
  int _propertyCount = 0;
  bool _isLoadingProperties = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletAddress().then((_) {
      _fetchPropertyCount();
    });
  }

  Future<void> _fetchWalletAddress() async {
    setState(() {
      _isLoadingWallet = true;
      _hasError = false;
    });

    try {
      final response = await ApiClient.dio.get('/auth/wallet');

      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _walletAddress = response.data['wallet_address'] ?? '';
          _isLoadingWallet = false;
        });
      } else {
        throw Exception('فشل في تحميل عنوان المحفظة');
      }
    } catch (e) {
      setState(() {
        _isLoadingWallet = false;
        _hasError = true;

        if (e.toString().contains('401')) {
          _errorMessage = 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى';
          // Navigate to login after showing message
          Future.delayed(Duration(seconds: 2), () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => AuthenticationScreen()),
              (route) => false,
            );
          });
        } else {
          _errorMessage = 'تعذر تحميل عنوان المحفظة';
        }
      });
    }
  }

  Future<void> _fetchPropertyCount() async {
    try {
      final response = await ApiClient.dio.get('/property-requests/owned');

      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _propertyCount = response.data['summary']['total'] ?? 0;
          _isLoadingProperties = false;
        });
      }
    } catch (e) {
      print('Error fetching property count: $e');
      setState(() {
        _isLoadingProperties = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ النص إلى الحافظة'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
        title: Text(
          "الملف الشخصي",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Add logout functionality here
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("تسجيل الخروج", textAlign: TextAlign.right),
                  content: Text("هل أنت متأكد من رغبتك في تسجيل الخروج؟",
                      textAlign: TextAlign.right),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("إلغاء"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AuthenticationScreen()),
                          (route) => false,
                        );
                      },
                      child: Text("تأكيد"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: _fetchWalletAddress,
          color: Colors.deepPurpleAccent,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Profile header with avatar
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.deepPurple.shade800,
                        Colors.deepPurpleAccent
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 30),
                      // Profile avatar with updated styling
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 7),
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Center(
                          child: Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : "؟",
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.w900,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Enhanced username display
                      Column(
                        children: [
                          Text(
                            widget.userName
                                .split(' ')
                                .first, // Only show the first name
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black.withOpacity(0.3),
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified,
                                    size: 16, color: Colors.white),
                                SizedBox(width: 5),
                                Text(
                                  "مستخدم موثق",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Wallet information card - full width
                Card(
                  elevation: 2,
                  margin: EdgeInsets.zero, // Remove default card margin
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        0), // Remove border radius for full-width look
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet,
                                color: Colors.deepPurpleAccent),
                            SizedBox(width: 8),
                            Text(
                              "عنوان المحفظة",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            if (!_isLoadingWallet && !_hasError)
                              IconButton(
                                icon: Icon(Icons.copy, color: Colors.grey),
                                onPressed: () =>
                                    _copyToClipboard(_walletAddress),
                                tooltip: "نسخ العنوان",
                              ),
                          ],
                        ),
                        Divider(),
                        SizedBox(height: 8),
                        if (_isLoadingWallet)
                          Center(
                            child: CircularProgressIndicator(
                              color: Colors.deepPurpleAccent,
                            ),
                          )
                        else if (_hasError)
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red, size: 48),
                                SizedBox(height: 8),
                                Text(
                                  _errorMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red),
                                ),
                                TextButton.icon(
                                  onPressed: _fetchWalletAddress,
                                  icon: Icon(Icons.refresh),
                                  label: Text("إعادة المحاولة"),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: [
                              // QR Code added here
                              Center(
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: QrImageView(
                                    data: _walletAddress,
                                    version: QrVersions.auto,
                                    size: 200.0,
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.all(10),
                                    eyeStyle: QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Colors.deepPurpleAccent,
                                    ),
                                    dataModuleStyle: QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Colors.deepPurple.shade900,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _walletAddress,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Additional user information cards can be added here
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.deepPurpleAccent),
                              SizedBox(width: 8),
                              Text(
                                "معلومات إضافية",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Divider(),
                          SizedBox(height: 8),
                          ListTile(
                            title: Text("عدد الممتلكات"),
                            trailing: _isLoadingProperties
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Text("$_propertyCount"),
                            contentPadding: EdgeInsets.symmetric(horizontal: 0),
                          ),
                          ListTile(
                            title: Text("آخر تسجيل دخول"),
                            trailing:
                                Text(DateTime.now().toString().split(' ')[0]),
                            contentPadding: EdgeInsets.symmetric(horizontal: 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
