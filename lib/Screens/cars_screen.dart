import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:intl/date_symbol_data_local.dart';
import 'package:app/utils/api_client.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<CarModel> _cars = [];
  int _totalCars = 0;
  String _selectedFilter = 'الكل';

  // Car type filter options
  final List<String> _filters = [
    'الكل',
    'سيدان',
    'دفع رباعي',
    'هاتشباك',
    'نقل',
    'أخرى'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the Arabic locale data
    initializeDateFormatting('ar', null).then((_) {
      _fetchCars();
    });
  }

  Future<void> _fetchCars() async {
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
            // Filter to include ONLY cars
            _cars = propertiesJson
                .map((json) => CarModel.fromJson(json))
                .toList()
                .where((property) => property.type == "سيارة")
                .toList();
            _totalCars = _cars.length;
            _isLoading = false;
          });
        } else {
          throw Exception('فشل في تحميل السيارات');
        }
      } else {
        throw Exception('فشل في تحميل السيارات');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  List<CarModel> get _filteredCars {
    if (_selectedFilter == 'الكل') {
      return _cars;
    }
    // For cars, we'll filter by car_model if available, otherwise fall back to description
    return _cars
        .where((car) =>
            car.carModel?.contains(_selectedFilter) == true ||
            car.description.contains(_selectedFilter))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "السيارات",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchCars,
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
              color: Colors.blueAccent,
            ),
            SizedBox(height: 16),
            Text(
              "جاري تحميل السيارات...",
              style: TextStyle(
                color: Colors.blueAccent,
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
              "حدث خطأ في تحميل السيارات",
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
              onPressed: _fetchCars,
              icon: Icon(Icons.refresh),
              label: Text("إعادة المحاولة"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_cars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car,
              color: Colors.grey,
              size: 80,
            ),
            SizedBox(height: 16),
            Text(
              "لا توجد سيارات",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "لم يتم العثور على أي سيارات مسجلة باسمك",
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
                    selectedColor: Colors.blueAccent.withOpacity(0.7),
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

        // Cars count
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "السيارات (${_filteredCars.length})",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _selectedFilter == 'الكل'
                    ? "جميع السيارات"
                    : "نوع: $_selectedFilter",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Cars list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchCars,
            color: Colors.blueAccent,
            child: _filteredCars.isEmpty
                ? Center(
                    child: Text(
                      "لا توجد سيارات متطابقة مع الفلتر المحدد",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _filteredCars.length,
                    itemBuilder: (context, index) {
                      final car = _filteredCars[index];
                      return _buildCarCard(car);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarCard(CarModel car) {
    // Format currency
    final currencyFormatter = NumberFormat("#,##0.00", "ar_EG");
    String formattedPrice = "${currencyFormatter.format(car.price)} جنيه";

    // Format date
    final dateFormatter = DateFormat("yyyy/MM/dd", "ar");
    String formattedDate = dateFormatter.format(car.date);

    // Extract car model/brand from description if available
    String carModelDisplay = car.carModel ?? "سيارة";

    // Car color options for display variation
    Color cardColor = Colors.blue;
    if (car.description.contains("حمراء")) {
      cardColor = Colors.red;
    } else if (car.description.contains("سوداء")) {
      cardColor = Colors.black87;
    } else if (car.description.contains("بيضاء")) {
      cardColor = Colors.blueGrey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to car details screen - future implementation
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
                  colors: [cardColor, cardColor.withOpacity(0.7)],
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
                    Icons.directions_car,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    carModelDisplay,
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

            // Car details
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (car.year != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.calendar_today,
                              color: Colors.grey[600], size: 20),
                          SizedBox(width: 8),
                          Text(
                            "موديل ${car.year}",
                            style: TextStyle(fontSize: 15),
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
                            car.description,
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
                      Icon(Icons.access_time,
                          color: Colors.grey[600], size: 20),
                      SizedBox(width: 8),
                      Text(
                        "تاريخ التسجيل: $formattedDate",
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
                      foregroundColor: cardColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Share document action
                    },
                    icon: Icon(Icons.share, size: 18),
                    label: Text("مشاركة المستند"),
                    style: TextButton.styleFrom(
                      foregroundColor: cardColor,
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

class CarModel {
  final String type; // Always "سيارة" for cars
  final String? carModel; // Extracted from description if possible
  final String description;
  final double price;
  final DateTime date;
  final int? year; // Car model year if available

  CarModel({
    required this.type,
    this.carModel,
    required this.description,
    required this.price,
    required this.date,
    this.year,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    // Extract car model from description if available
    String? carModel;
    String description = json['full_description'] ?? '';

    // Try to extract car year from description using regex
    int? year;

    // Simple regex to find 4-digit years between 1900 and 2099
    RegExp yearRegex = RegExp(r'(19|20)\d{2}');
    Match? yearMatch = yearRegex.firstMatch(description);
    if (yearMatch != null) {
      try {
        year = int.parse(yearMatch.group(0) ?? '');
      } catch (e) {
        // Failed to parse year, keep as null
      }
    }

    // Try to extract car model from additional_info if available
    Map<String, dynamic>? additionalInfo = json['additional_info'];
    if (additionalInfo != null && additionalInfo['car_model'] != null) {
      carModel = additionalInfo['car_model'];
    } else {
      // Try to extract from description (basic implementation)
      List<String> commonCarBrands = [
        'تويوتا',
        'هوندا',
        'نيسان',
        'مرسيدس',
        'بي إم دبليو',
        'أودي',
        'شيفروليه',
        'فورد',
        'هيونداي',
        'كيا'
      ];

      for (String brand in commonCarBrands) {
        if (description.contains(brand)) {
          carModel = brand;
          break;
        }
      }
    }

    return CarModel(
      type: json['property_type'] ?? '',
      carModel: carModel,
      description: description,
      price: (json['property_price'] ?? 0).toDouble(),
      date: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'])
          : DateTime.now(),
      year: year,
    );
  }
}
