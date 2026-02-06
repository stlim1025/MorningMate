import 'package:flutter/material.dart';
import '../../character/screens/shop_screen.dart';
import '../../common/widgets/room_action_button.dart';

class StoreButton extends StatelessWidget {
  const StoreButton({super.key});

  @override
  Widget build(BuildContext context) {
    return RoomActionButton(
      iconPath: 'assets/icons/Store_Icon.png',
      label: '상점',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ShopScreen()),
        );
      },
    );
  }
}
