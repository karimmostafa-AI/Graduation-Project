import 'package:flutter/material.dart';
import 'package:app/utils/api_client.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:intl/date_symbol_data_local.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<TransactionModel> _transactions = [];
  String? _selectedStatusFilter;

  // Filter options for transaction status
  final List<Map<String, String?>> _statusFilters = [
    {'value': null, 'label': 'الكل'},
    {'value': 'pending', 'label': 'قيد الانتظار'},
    {'value': 'approved', 'label': 'موافق عليها'},
    {'value': 'rejected', 'label': 'مرفوضة'},
    {'value': 'completed', 'label': 'مكتملة'},
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ar', null).then((_) {
      _fetchTransactions();
    });
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response =
          await ApiClient.dio.get('/property-requests/requsits_history');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> transactionsJson = data['requests'] ?? [];

          setState(() {
            _transactions = transactionsJson
                .map((json) => TransactionModel.fromJson(json))
                .toList();
            _isLoading = false;
          });
          await _fetchUserWalletAddress();
        } else {
          throw Exception('فشل في تحميل المعاملات');
        }
      } else {
        throw Exception('فشل في تحميل المعاملات');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      print('Error fetching transactions: $e');
    }
  }

  Future<void> _fetchUserWalletAddress() async {
    try {
      final response = await ApiClient.dio.get('/auth/wallet');
      if (response.statusCode == 200 && response.data != null) {
        final walletAddress = response.data['wallet_address'] ?? '';

        setState(() {
          // Update all transactions with the user's wallet address
          for (var transaction in _transactions) {
            transaction.currentUserWalletAddress = walletAddress;
          }
        });
      }
    } catch (e) {
      print('Error fetching wallet address: $e');
    }
  }

  List<TransactionModel> get filteredTransactions {
    if (_selectedStatusFilter == null) {
      return _transactions;
    }
    return _transactions
        .where((tx) => tx.status == _selectedStatusFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "سجل المعاملات",
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
            onPressed: _fetchTransactions,
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
              "جاري تحميل المعاملات...",
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
              "حدث خطأ في تحميل المعاملات",
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
              onPressed: _fetchTransactions,
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

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              color: Colors.grey,
              size: 80,
            ),
            SizedBox(height: 16),
            Text(
              "لا توجد معاملات حتى الآن",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              "المعاملات التي تقوم بها ستظهر هنا",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status filter
        Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "تصفية حسب الحالة",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statusFilters.length,
                  itemBuilder: (context, index) {
                    final filter = _statusFilters[index];
                    final bool isSelected =
                        _selectedStatusFilter == filter['value'];

                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ChoiceChip(
                        label: Text(filter['label']!),
                        selected: isSelected,
                        selectedColor: Colors.deepPurpleAccent.withOpacity(0.7),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatusFilter =
                                selected ? filter['value'] : null;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Transactions count
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "${filteredTransactions.length} معاملة",
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Transactions list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchTransactions,
            color: Colors.deepPurpleAccent,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
                return _buildTransactionCard(transaction);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    // Format currency
    final currencyFormatter = NumberFormat("#,##0.00", "ar_EG");
    String formattedPrice =
        "${currencyFormatter.format(transaction.price)} جنيه";

    // Format dates
    final dateFormatter = DateFormat("yyyy/MM/dd", "ar");
    String formattedTransactionDate =
        dateFormatter.format(transaction.transactionDate);
    String formattedCreatedDate = dateFormatter.format(transaction.createdAt);

    // Choose icon based on property type
    IconData propertyIcon;
    final Color iconColor;

    switch (transaction.propertyType) {
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

    // Choose color and text based on status
    Color statusColor;
    String statusText;

    switch (transaction.status) {
      case "pending":
        statusColor = Colors.amber;
        statusText = "قيد الانتظار";
        break;
      case "approved":
        statusColor = Colors.green;
        statusText = "تمت الموافقة";
        break;
      case "rejected":
        statusColor = Colors.red;
        statusText = "مرفوض";
        break;
      case "completed":
        statusColor = Colors.blue;
        statusText = "مكتمل";
        break;
      default:
        statusColor = Colors.grey;
        statusText = "غير معروف";
    }

    bool isSellerTransaction = transaction.sellerWalletAddress.toLowerCase() ==
        transaction.currentUserWalletAddress?.toLowerCase();

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.9),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                topLeft: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(transaction.status),
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Spacer(),
                Text(
                  isSellerTransaction ? "بائع" : "مشتري",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Transaction Info
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property type and ID row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(propertyIcon, color: iconColor),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.propertyType,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "معاملة #${transaction.id}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Text(
                      formattedPrice,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),
                Divider(),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    transaction.description,
                    style: TextStyle(fontSize: 15),
                  ),
                ),

                if (transaction.propertyAddress != null &&
                    transaction.propertyAddress!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on,
                            color: Colors.grey[600], size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            transaction.propertyAddress!,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Dates
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: Colors.grey[600], size: 18),
                    SizedBox(width: 8),
                    Text(
                      "تاريخ المعاملة: $formattedTransactionDate",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey[600], size: 18),
                    SizedBox(width: 8),
                    Text(
                      "تاريخ الإنشاء: $formattedCreatedDate",
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
                  label: Text("التفاصيل"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurpleAccent,
                  ),
                ),
                if (transaction.ownershipDocument.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      // Download document action
                    },
                    icon: Icon(Icons.download, size: 18),
                    label: Text("تنزيل المستند"),
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }
}

class TransactionModel {
  final int id;
  final String sellerWalletAddress;
  final String buyerWalletAddress;
  final String description;
  final double price;
  final String ownershipDocument;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String propertyType;
  final DateTime transactionDate;
  final String? propertyAddress;
  String? currentUserWalletAddress; // This should be set after fetching

  TransactionModel({
    required this.id,
    required this.sellerWalletAddress,
    required this.buyerWalletAddress,
    required this.description,
    required this.price,
    required this.ownershipDocument,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.propertyType,
    required this.transactionDate,
    this.propertyAddress,
    this.currentUserWalletAddress,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // This would ideally get the current user's wallet address from a provider/service
    // For now, let's assume it's stored elsewhere and will be set after fetch

    return TransactionModel(
      id: json['request_id'] ?? 0,
      sellerWalletAddress: json['seller_wallet_address'] ?? '',
      buyerWalletAddress: json['buyer_wallet_address'] ?? '',
      description: json['full_description'] ?? '',
      price: double.tryParse(json['property_price'].toString()) ?? 0.0,
      ownershipDocument: json['ownership_document'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      propertyType: json['property_type'] ?? '',
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'])
          : DateTime.now(),
      propertyAddress: json['property_address'],
    );
  }
}
