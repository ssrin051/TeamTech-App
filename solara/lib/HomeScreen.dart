import 'package:flutter_svg/flutter_svg.dart';

class BluetoothIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/bluetooth.svg',
      width: 40,
      height: 40,
    );
  }
}
