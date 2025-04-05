import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:intl/date_symbol_data_local.dart';
import 'package:app/utils/api_client.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<PropertyModel> _properties = [];
  int _totalProperties = 0;
  String _selectedFilter = 'الكل';

  // Filter options
  final List<String> _filters = [
    'الكل',
    'شقة',
    'فيلا',
    'أرض',
    'محل تجاري',
    'مكتب'
  ];

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
                .toList()
                // Filter out cars
                .where((property) => property.type != "سيارة")
                .toList();
            _totalProperties = _properties.length;
            _isLoading = false;
          });
        } else {
          throw Exception('فشل في تحميل العقارات');
        }
      } else {
        throw Exception('فشل في تحميل العقارات');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  List<PropertyModel> get _filteredProperties {
    if (_selectedFilter == 'الكل') {
      return _properties;
    }
    return _properties
        .where((property) => property.type == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "العقارات",
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
              "جاري تحميل العقارات...",
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
              "حدث خطأ في تحميل العقارات",
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
              "لا توجد عقارات",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "لم يتم العثور على أي عقارات مسجلة باسمك",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter chips
        Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 1,
                offset: Offset(0, 1),
              )
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      }
                    },
                    selectedColor: Colors.deepPurpleAccent.withOpacity(0.7),
                    labelStyle: TextStyle(
                      color: _selectedFilter == filter
                          ? Colors.white
                          : Colors.black,
                      fontWeight: _selectedFilter == filter
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Properties count
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "العقارات (${_filteredProperties.length})",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _selectedFilter == 'الكل'
                    ? "جميع العقارات"
                    : "نوع: $_selectedFilter",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Properties list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchProperties,
            color: Colors.deepPurpleAccent,
            child: _filteredProperties.isEmpty
                ? Center(
                    child: Text(
                      "لا توجد عقارات متطابقة مع الفلتر المحدد",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _filteredProperties.length,
                    itemBuilder: (context, index) {
                      final property = _filteredProperties[index];
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
    Color iconColor;

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
      default:
        propertyIcon = Icons.real_estate_agent;
        iconColor = Colors.deepPurple;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to property details screen - future implementation
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and price
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconColor, iconColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
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
                      foregroundColor: iconColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Share document action
                    },
                    icon: Icon(Icons.share, size: 18),
                    label: Text("مشاركة المستند"),
                    style: TextButton.styleFrom(
                      foregroundColor: iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
