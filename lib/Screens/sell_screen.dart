import 'package:app/Screens/authentication_screen.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:app/utils/api_client.dart';

class SellScreen extends StatefulWidget {
  @override
  _SellScreenState createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _dateController = TextEditingController();
  TextEditingController _sellerAddressController =
      TextEditingController(text: "0x6A1D6aC7B8A45E92bAFe4c0dBb0C761C8e845b1E");
  TextEditingController _buyerAddressController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _propertyAddressController = TextEditingController();
  TextEditingController _propertyTypeController = TextEditingController();
  File? _ownershipDocument;
  String? _documentName;
  bool _isLoading = false;

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _ownershipDocument = File(result.files.single.path!);
          _documentName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في اختيار الملف: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_ownershipDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار ملف وثيقة الملكية'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Debug print to verify property type before submission
      print("Selected property type: ${_propertyTypeController.text}");

      // Create form data
      FormData formData = FormData.fromMap({
        'seller_wallet_address': _sellerAddressController.text,
        'buyer_wallet_address': _buyerAddressController.text,
        'full_description': _descriptionController.text,
        'property_type': _propertyTypeController.text,
        'transaction_date': _dateController.text,
        'property_price': double.parse(_priceController.text),
        if (_propertyTypeController.text != "سيارة")
          'property_address': _propertyAddressController.text,
        'ownership_document': await MultipartFile.fromFile(
          _ownershipDocument!.path,
          filename: _documentName,
        ),
      });

      // Debug print to verify form data (comment out in production)
      print(
          "Form data fields: ${formData.fields.map((f) => '${f.key}: ${f.value}').join(', ')}");

      // Send request using the ApiClient
      final response = await ApiClient.dio.post(
        '/property-requests',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الطلب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form or navigate back
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'حدث خطأ: ${response.data['message'] ?? 'فشل إرسال الطلب'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'خطأ في الاتصال';
      bool shouldShowRetry = false;

      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          errorMessage = 'خطأ في الاتصال: ${e.message}';
          shouldShowRetry = true;
        } else if (e.response != null) {
          final statusCode = e.response?.statusCode ?? 0;
          if (statusCode == 401) {
            errorMessage = 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى';
            // Navigate to login after showing message
            Future.delayed(Duration(seconds: 2), () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => AuthenticationScreen()),
                (route) => false,
              );
            });
          } else if (e.toString().contains('Only PDF files are allowed')) {
            errorMessage = 'يجب أن يكون الملف بصيغة PDF فقط';
          } else {
            errorMessage = 'خطأ: ${e.response?.data['message'] ?? e.message}';
          }
        }
      } else {
        errorMessage = 'خطأ: ${e.toString()}';
      }

      final snackBar = SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        action: shouldShowRetry
            ? SnackBarAction(
                label: 'إعادة المحاولة',
                textColor: Colors.white,
                onPressed: _submitForm,
              )
            : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "بيع ممتلكات",
          textAlign: TextAlign.right,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "عقد بيع",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _dateController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: "تاريخ العملية",
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _dateController.text =
                                  "${pickedDate.toIso8601String().split('T')[0]}";
                            });
                          }
                        },
                      ),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى تحديد التاريخ';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _sellerAddressController,
                    readOnly: true,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: "عنوان البلوكشين للبائع",
                      suffixIcon: Icon(Icons.person),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'عنوان البائع مطلوب';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _buyerAddressController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: "عنوان البلوكشين للمشتري",
                      suffixIcon: Icon(Icons.person_add),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'عنوان المشتري مطلوب';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _propertyTypeController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: "نوع العقد",
                      suffixIcon: Icon(Icons.article),
                      alignLabelWithHint: true,
                      hintText: "شقة، فيلا، أرض، محل تجاري، مكتب، سيارة",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال نوع العقد';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  if (_propertyTypeController.text != "سيارة") ...[
                    TextFormField(
                      controller: _propertyAddressController,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: "عنوان العقار",
                        suffixIcon: Icon(Icons.location_on),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (_propertyTypeController.text != "سيارة" &&
                            (value == null || value.isEmpty)) {
                          return 'عنوان العقار مطلوب';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _descriptionController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: "الوصف",
                      suffixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الوصف مطلوب';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "سعر الممتلكات",
                      suffixIcon: Icon(Icons.attach_money),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'السعر مطلوب';
                      }
                      if (double.tryParse(value) == null) {
                        return 'يرجى إدخال رقم صحيح';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  // Document upload section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "وثيقة الملكية",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _pickDocument,
                          icon: Icon(Icons.upload_file),
                          label: Text("اختيار ملف"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade100,
                            foregroundColor: Colors.deepPurple,
                          ),
                        ),
                        if (_documentName != null) ...[
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _documentName!,
                                  style: TextStyle(color: Colors.green),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _ownershipDocument = null;
                                    _documentName = null;
                                  });
                                },
                                tooltip: 'حذف الملف',
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "إرسال الطلب",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
