import 'package:flutter/material.dart';
import 'package:app/utils/constants.dart';
import 'package:app/utils/validators.dart';
import 'package:app/Screens/home_screen.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:app/utils/api_client.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Track loading state

  // Controllers for all fields
  final _nationalIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Error messages for real-time validation
  String? _nationalIdError;
  String? _passwordError;
  String? _usernameError;
  String? _confirmPasswordError;
  String? _emailError;
  String? _phoneError;

  @override
  void dispose() {
    _nationalIdController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    // Validate all fields before submission
    _validateNationalId(_nationalIdController.text);
    _validatePassword(_passwordController.text);

    if (!isLogin) {
      _validateUsername(_usernameController.text);
      _validateConfirmPassword(_confirmPasswordController.text);
      _validateEmail(_emailController.text);
      _validatePhone(_phoneController.text);
    }

    // Check if there are any errors
    if (_nationalIdError == null &&
        _passwordError == null &&
        (isLogin ||
            (_usernameError == null &&
                _confirmPasswordError == null &&
                _emailError == null &&
                _phoneError == null))) {
      print("Form validation passed, attempting submission");

      setState(() {
        _isLoading = true; // Set loading state to true before processing
      });

      // Create Dio instance with CookieManager
      final dio = Dio();
      final cookieJar = CookieJar();
      dio.interceptors.add(CookieManager(cookieJar));
      dio.options.connectTimeout = Duration(seconds: 10); // 10 seconds

      try {
        if (isLogin) {
          // For login, authenticate against the database
          print("Sending API request to login endpoint");
          try {
            print(
                "Attempting login with national ID: ${_nationalIdController.text}");

            final response = await ApiClient.dio.post(
              '/auth/login', // Notice the URL is shorter since baseUrl is set
              data: {
                'national_id': _nationalIdController.text,
                'password': _passwordController.text,
              },
            );

            print("Response status code: ${response.statusCode}");
            print("Response data: ${response.data}");

            if (response.statusCode == 200) {
              // Login successful
              final responseData = response.data;

              // Store user token if provided by API using a method like SharedPreferences
              // For example:
              // SharedPreferences prefs = await SharedPreferences.getInstance();
              // prefs.setString('auth_token', responseData['token']);

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تسجيل الدخول بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );

              // Navigate to home screen after successful login
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            } else {
              // Login failed
              final errorData = response.data;
              String errorMessage;

              // Handle specific error cases
              if (response.statusCode == 401) {
                errorMessage = 'الرقم القومي أو كلمة المرور غير صحيحة';
              } else if (response.statusCode == 404) {
                errorMessage = 'لم يتم العثور على المستخدم';
              } else {
                errorMessage = errorData['message'] ?? 'فشل تسجيل الدخول';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            print("API request failed with error type: ${e.runtimeType}");
            print("Error details: ${e.toString()}");
            // Handle network or server errors
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('خطأ في الاتصال: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // For signup, make API request
          print("Sending API request to signup endpoint");
          try {
            final signupData = {
              'username': _usernameController.text,
              'password': _passwordController.text,
              'phone_number': _phoneController.text,
              'national_id': _nationalIdController.text,
              'email': _emailController.text,
            };
            print("Attempting API request with body: $signupData");

            final response = await dio.post(
              'http://192.168.1.8:5000/api/auth/signup',
              options: Options(headers: {'Content-Type': 'application/json'}),
              data: signupData,
            );

            print("Response status code: ${response.statusCode}");
            print("Response data: ${response.data}");

            if (response.statusCode == 200 || response.statusCode == 201) {
              // Signup successful
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إنشاء الحساب بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );

              // Navigate to home screen after successful signup
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            } else {
              // Signup failed
              final errorData = response.data;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      errorData['message'] ?? 'حدث خطأ أثناء إنشاء الحساب'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            print("API request failed with error type: ${e.runtimeType}");
            print("Error details: ${e.toString()}");
            // Handle network or server errors
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('خطأ في الاتصال: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } finally {
        // Reset loading state regardless of success or failure
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      print("Form validation failed");
      print("National ID error: $_nationalIdError");
      print("Password error: $_passwordError");
      print("Username error: $_usernameError");
      print("Confirm password error: $_confirmPasswordError");
      print("Email error: $_emailError");
      print("Phone error: $_phoneError");
    }
  }

  // Validation methods
  void _validateNationalId(String value) {
    setState(() {
      _nationalIdError = Validators.validateNationalId(value);
    });
  }

  void _validatePassword(String value) {
    setState(() {
      _passwordError = Validators.validatePassword(value);

      // If password changes and confirm password was already entered
      if (!isLogin && _confirmPasswordController.text.isNotEmpty) {
        _validateConfirmPassword(_confirmPasswordController.text);
      }
    });
  }

  void _validateUsername(String value) {
    setState(() {
      _usernameError = Validators.validateUsername(value);
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      _confirmPasswordError =
          Validators.validateConfirmPassword(value, _passwordController.text);
    });
  }

  void _validateEmail(String value) {
    setState(() {
      _emailError = Validators.validateEmail(value);
    });
  }

  void _validatePhone(String value) {
    setState(() {
      _phoneError = Validators.validatePhone(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss the keyboard when tapping outside any text field
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Image.asset(
                      'assets/Images/GP_Logo.png',
                      height: 120,
                    ),
                    const SizedBox(height: 20),

                    // App Name with creative styling
                    Text(
                      AppConstants.appNameStyled,
                      style: AppConstants.appNameStyle,
                    ),
                    const SizedBox(height: 40),

                    // Toggle between login and signup
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildToggleButton("تسجيل الدخول", isLogin),
                        const SizedBox(width: 20),
                        _buildToggleButton("حساب جديد", !isLogin),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Login Mode Fields
                          if (isLogin) ...[
                            // National ID field
                            TextFormField(
                              controller: _nationalIdController,
                              keyboardType: TextInputType.number,
                              decoration: AppConstants.textFieldDecoration(
                                'الرقم القومي',
                                Icons.credit_card,
                              ).copyWith(
                                errorText: _nationalIdError,
                              ),
                              onChanged: _validateNationalId,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 15),

                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              decoration: AppConstants.textFieldDecoration(
                                'كلمة المرور',
                                Icons.lock,
                              ).copyWith(
                                errorText: _passwordError,
                              ),
                              obscureText: true,
                              onChanged: _validatePassword,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                          ],

                          // Signup Mode Fields
                          if (!isLogin) ...[
                            // 1. Username field
                            TextFormField(
                              controller: _usernameController,
                              decoration: AppConstants.textFieldDecoration(
                                'اسم المستخدم',
                                Icons.person,
                              ).copyWith(
                                errorText: _usernameError,
                              ),
                              onChanged: _validateUsername,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 15),

                            // 2. National ID field
                            TextFormField(
                              controller: _nationalIdController,
                              keyboardType: TextInputType.number,
                              decoration: AppConstants.textFieldDecoration(
                                'الرقم القومي',
                                Icons.credit_card,
                              ).copyWith(
                                errorText: _nationalIdError,
                              ),
                              onChanged: _validateNationalId,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 15),

                            // 3. Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: AppConstants.textFieldDecoration(
                                'البريد الإلكتروني',
                                Icons.email,
                              ).copyWith(
                                errorText: _emailError,
                              ),
                              onChanged: _validateEmail,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 15),

                            // 4. Password field
                            TextFormField(
                              controller: _passwordController,
                              decoration: AppConstants.textFieldDecoration(
                                'كلمة المرور',
                                Icons.lock,
                              ).copyWith(
                                errorText: _passwordError,
                              ),
                              obscureText: true,
                              onChanged: _validatePassword,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 15),

                            // 5. Confirm Password field
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: AppConstants.textFieldDecoration(
                                'تأكيد كلمة المرور',
                                Icons.lock,
                              ).copyWith(
                                errorText: _confirmPasswordError,
                              ),
                              obscureText: true,
                              onChanged: _validateConfirmPassword,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 15),

                            // 6. Phone field
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: AppConstants.textFieldDecoration(
                                'رقم الهاتف',
                                Icons.phone,
                              ).copyWith(
                                errorText: _phoneError,
                              ),
                              onChanged: _validatePhone,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                          ],

                          const SizedBox(height: 30),

                          // Submit Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text('جاري المعالجة...',
                                          style: TextStyle(fontSize: 18)),
                                    ],
                                  )
                                : Text(
                                    isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                          ),
                        ],
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
  }

  Widget _buildToggleButton(String title, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isLogin = title == "تسجيل الدخول";
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppConstants.primaryColor,
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : AppConstants.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
