import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ShippingService {
  // Tọa độ giả định của Cửa hàng (Bạn có thể thay bằng tọa độ thật của shop)
  static const double shopLat = 10.762622;
  static const double shopLng = 106.660172;

  // 1. Hàm lấy vị trí hiện tại của khách hàng
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  // 2. Hàm tính phí ship dựa trên khoảng cách (km)
  double calculateShippingFee(double distanceInMeters) {
    double distanceInKm = distanceInMeters / 1000;
    
    if (distanceInKm <= 2) return 15000; // Dưới 2km phí 15k
    if (distanceInKm <= 5) return 25000; // 2-5km phí 25k
    return 25000 + (distanceInKm - 5) * 5000; // Trên 5km cộng thêm 5k/km
  }

  // 3. Hàm lấy khoảng cách từ địa chỉ text (Geocoding)
  Future<double> getDistanceToAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        double distance = Geolocator.distanceBetween(
          shopLat, shopLng,
          locations.first.latitude, locations.first.longitude
        );
        return distance;
      }
    } catch (e) {
      print("Lỗi Geocoding: $e");
    }
    return 5000; // Mặc định giả định 5km nếu lỗi
  }
}
