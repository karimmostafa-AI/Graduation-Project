import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:intl/date_symbol_data_local.dart'; // Add this import
import 'package:app/utils/api_client.dart';

class MyAssetsScreen extends StatefulWidget {
  const MyAssetsScreen({super.key});

  @override
  State<MyAssetsScreen> createState() => _MyAssetsScreenState();
}

class _MyAssetsScreenState extends State<MyAssetsScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<PropertyModel> _properties = [];
  int _totalProperties = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the Arabic locale data
    initializeDateFormatting('ar', null).then((_) {
      _fetchProperties();
    });
  }

  Future<void> _fetchProperties() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await ApiClient.dio.get('/property-requests/owned');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> propertiesJson = data['properties'] ?? [];

          setState(() {
            _properties = propertiesJson
                .map((json) => PropertyModel.fromJson(json))
                .toList();
            _totalProperties = data['summary']['total'] ?? 0;
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load properties');
        }
      } else {
        throw Exception('Failed to load properties');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "ممتلكاتي",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchProperties,
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.deepPurpleAccent,
            ),
            SizedBox(height: 16),
            Text(
              "جاري تحميل الممتلكات...",
              style: TextStyle(
                color: Colors.deepPurpleAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              "حدث خطأ في تحميل الممتلكات",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchProperties,
              icon: Icon(Icons.refresh),
              label: Text("إعادة المحاولة"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_properties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work,
              color: Colors.grey,
              size: 80,
            ),
            SizedBox(height: 16),
            Text(
              "لا توجد ممتلكات",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "لم يتم العثور على أي ممتلكات مسجلة باسمك",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "إجمالي الممتلكات: $_totalProperties",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  // Add filter options here if needed
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchProperties,
            color: Colors.deepPurpleAccent,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _properties.length,
              itemBuilder: (context, index) {
                final property = _properties[index];
                return _buildPropertyCard(property);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(PropertyModel property) {
    // Format currency
    final currencyFormatter = NumberFormat("#,##0.00", "ar_EG");
    String formattedPrice = "${currencyFormatter.format(property.price)} جنيه";

    // Format date
    final dateFormatter = DateFormat("yyyy/MM/dd", "ar");
    String formattedDate = dateFormatter.format(property.date);

    // Choose icon based on property type
    IconData propertyIcon;
    final Color iconColor;

    switch (property.type) {
      case "شقة":
        propertyIcon = Icons.apartment;
        iconColor = Colors.blue;
        break;
      case "فيلا":
        propertyIcon = Icons.home;
        iconColor = Colors.green;
        break;
      case "أرض":
        propertyIcon = Icons.landscape;
        iconColor = Colors.brown;
        break;
      case "محل تجاري":
        propertyIcon = Icons.storefront;
        iconColor = Colors.orange;
        break;
      case "مكتب":
        propertyIcon = Icons.business;
        iconColor = Colors.indigo;
        break;
      case "سيارة":
        propertyIcon = Icons.directions_car;
        iconColor = Colors.red;
        break;
      default:
        propertyIcon = Icons.real_estate_agent;
        iconColor = Colors.deepPurple;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with type and price
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withOpacity(0.9),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                topLeft: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  propertyIcon,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  property.type,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Spacer(),
                Text(
                  formattedPrice,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Property details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (property.address != null && property.address!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on,
                            color: Colors.grey[600], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            property.address!,
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description,
                          color: Colors.grey[600], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          property.description,
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: Colors.grey[600], size: 20),
                    SizedBox(width: 8),
                    Text(
                      "تاريخ العملية: $formattedDate",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // View details action
                  },
                  icon: Icon(Icons.visibility, size: 18),
                  label: Text("عرض التفاصيل"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurpleAccent,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Share document action
                  },
                  icon: Icon(Icons.share, size: 18),
                  label: Text("مشاركة المستند"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurpleAccent,
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

class PropertyModel {
  final String type;
  final String? address;
  final String description;
  final double price;
  final DateTime date;

  PropertyModel({
    required this.type,
    this.address,
    required this.description,
    required this.price,
    required this.date,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      type: json['property_type'] ?? '',
      address: json['property_address'],
      description: json['full_description'] ?? '',
      price: (json['property_price'] ?? 0).toDouble(),
      date: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'])
          : DateTime.now(),
    );
  }
}
