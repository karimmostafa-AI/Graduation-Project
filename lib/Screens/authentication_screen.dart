import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:app/utils/constants.dart';
import 'package:app/utils/validators.dart';
import 'package:app/Screens/home_screen.dart';
import 'package:app/utils/api_client.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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
    // Validate fields
    _validateNationalId(_nationalIdController.text);
    _validatePassword(_passwordController.text);

    if (!isLogin) {
      _validateUsername(_usernameController.text);
      _validateConfirmPassword(_confirmPasswordController.text);
      _validateEmail(_emailController.text);
      _validatePhone(_phoneController.text);
    }

    // Proceed only if no errors
    if (_nationalIdError == null &&
        _passwordError == null &&
        (isLogin ||
            (_usernameError == null &&
                _confirmPasswordError == null &&
                _emailError == null &&
                _phoneError == null))) {
      print("Form validation passed, attempting submission");

      setState(() {
        _isLoading = true;
      });

      try {
        if (isLogin) {
          // Login Mode: use correct endpoint and required fields
          print("Sending API request to login endpoint");
          final loginData = {
            'national_id': _nationalIdController.text,
            'password': _passwordController.text,
          };
          print("Attempting API request with body: $loginData");

          final response = await ApiClient.dio.post(
            '/auth/login',
            data: loginData,
          );

          print("Response status code: ${response.statusCode}");
          print("Response data: ${response.data}");

          if (response.statusCode == 200) {
            // Extract username from response
            final responseData = response.data;

            // Extract username from the nested user object
            final username = responseData['user']['username'];

            if (username == null) {
              print(
                  "Warning: Backend did not return a username in the response");
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تسجيل الدخول بنجاح'),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  userName:
                      username ?? "مستخدم", // Fallback if username is null
                ),
              ),
            );
          } else {
            // Handle login errors
            final errorData = response.data;
            String errorMessage;
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
        } else {
          // Signup Mode: use shared ApiClient.dio instance with proper endpoint
          print("Sending API request to signup endpoint");
          final signupData = {
            'username': _usernameController.text,
            'national_id': _nationalIdController.text,
            'email': _emailController.text,
            'password': _passwordController.text,
            'phone_number': _phoneController.text,
          };
          print("Attempting API request with body: $signupData");

          final response = await ApiClient.dio.post(
            '/auth/signup',
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

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      HomeScreen(userName: _usernameController.text)),
            );
          } else {
            // Handle signup errors
            final errorData = response.data;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(errorData['message'] ?? 'حدث خطأ أثناء إنشاء الحساب'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'خطأ في الاتصال';

        // Handle DioError specifically
        if (e is DioException && e.response != null) {
          final statusCode = e.response?.statusCode ?? 0;
          final errorData = e.response?.data ?? {};

          switch (statusCode) {
            case 400:
              // Handle validation errors
              break;
            case 409:
              // Handle conflict errors - but ignore username conflicts
              if (errorData['error']
                      ?.contains('National ID already registered') ??
                  false) {
                errorMessage = 'الرقم القومي مسجل بالفعل';
                _setFieldError(_nationalIdController, _nationalIdError);
              } else if (errorData['error']
                      ?.contains('Email already registered') ??
                  false) {
                errorMessage = 'البريد الإلكتروني مسجل بالفعل';
                _setFieldError(_emailController, _emailError);
              } else if (errorData['error']
                      ?.contains('Phone number already registered') ??
                  false) {
                errorMessage = 'رقم الهاتف مسجل بالفعل';
                _setFieldError(_phoneController, _phoneError);
              } else if (errorData['error']
                      ?.contains('Username already exists') ??
                  false) {
                // Don't show error for username, just continue with signup
                // Skip showing the error message
                return; // Skip the error message display
              } else {
                errorMessage =
                    errorData['error'] ?? 'البيانات المدخلة مستخدمة بالفعل';
              }
              break;
            // Other cases remain the same
          }
        } else if (e is DioException &&
            e.type == DioExceptionType.connectionTimeout) {
          errorMessage =
              'انتهت مهلة الاتصال، الرجاء التحقق من اتصالك بالإنترنت';
        } else if (e is DioException &&
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'تأخر الرد من الخادم، الرجاء المحاولة لاحقاً';
        } else if (e is DioException &&
            e.type == DioExceptionType.connectionError) {
          errorMessage =
              'فشل الاتصال بالخادم، الرجاء التحقق من اتصالك بالإنترنت';
        } else {
          errorMessage = 'خطأ: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'إغلاق',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      } finally {
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
      // Dismiss keyboard when tapping outside text fields
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
                    Image.asset(
                      'assets/Images/gp_logo.png',
                      height: 120,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppConstants.appNameStyled,
                      style: AppConstants.appNameStyle,
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildToggleButton("تسجيل الدخول", isLogin),
                        const SizedBox(width: 20),
                        _buildToggleButton("حساب جديد", !isLogin),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (isLogin) ...[
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
                          if (!isLogin) ...[
                            TextFormField(
                              controller: _usernameController,
                              decoration: AppConstants.textFieldDecoration(
                                'الاسم رباعي',
                                Icons.person,
                              ).copyWith(
                                errorText: _usernameError,
                              ),
                              onChanged: _validateUsername,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 15),
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

  void _setFieldError(TextEditingController controller, String? errorVariable) {
    // Highlight the field with error
    setState(() {
      if (controller == _usernameController) {
        _usernameError = 'هذا الاسم مستخدم بالفعل';
      } else if (controller == _nationalIdController) {
        _nationalIdError = 'الرقم القومي مسجل بالفعل';
      } else if (controller == _emailController) {
        _emailError = 'البريد الإلكتروني مسجل بالفعل';
      } else if (controller == _phoneController) {
        _phoneError = 'رقم الهاتف مسجل بالفعل';
      }
    });
  }
}
