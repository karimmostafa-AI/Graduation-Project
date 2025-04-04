import 'package:app/Screens/buy_screen.dart';
import 'package:app/Screens/property_owned.dart';
import 'package:app/Screens/sell_screen.dart';
import 'package:app/Screens/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'quick_action_item.dart';

class QuickActions extends StatelessWidget {
  void navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text("الإجراءات السريعة",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            QuickActionItem(
                icon: Icons.sell,
                label: "بيع الممتلكات",
                onTap: () => navigateTo(context, SellScreen())),
            QuickActionItem(
                icon: Icons.shopping_cart,
                label: "شراء",
                onTap: () => navigateTo(context, BuyScreen())),
            QuickActionItem(
                icon: Icons.account_balance_wallet,
                label: "ممتلكاتي",
                onTap: () => navigateTo(context, MyAssetsScreen())),
            QuickActionItem(
                icon: Icons.receipt,
                label: "العقود",
                onTap: () => navigateTo(context, TransactionsScreen())),
          ],
        ),
      ],
    );
  }
}
