import 'package:flutter/material.dart';
import 'package:fodd/Views/LoginScreen.dart';
import '../Utils/Constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Nhiều món ăn ngon",
      "subtitle": "Khám phá hàng ngàn món ăn hấp dẫn từ các nhà hàng nổi tiếng xung quanh bạn.",
      "image": "https://cdn-icons-png.flaticon.com/512/2276/2276931.png"
    },
    {
      "title": "Giao hàng nhanh chóng",
      "subtitle": "Đội ngũ shipper chuyên nghiệp sẽ đưa món ăn đến tận tay bạn trong thời gian ngắn nhất.",
      "image": "https://cdn-icons-png.flaticon.com/512/2830/2830305.png"
    },
    {
      "title": "Thanh toán dễ dàng",
      "subtitle": "Hỗ trợ nhiều hình thức thanh toán tiện lợi: Tiền mặt, Momo, Thẻ ngân hàng.",
      "image": "https://cdn-icons-png.flaticon.com/512/1019/1019607.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) => Column(
                  children: [
                    const Spacer(),
                    Image.network(_onboardingData[index]["image"]!, height: 250),
                    const Spacer(),
                    Text(
                      _onboardingData[index]["title"]!,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kprimaryColor),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        _onboardingData[index]["subtitle"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 5),
                        height: 6,
                        width: _currentPage == index ? 20 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? kprimaryColor : Colors.grey,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kprimaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () {
                          if (_currentPage == _onboardingData.length - 1) {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen()));
                          } else {
                            _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                          }
                        },
                        child: Text(
                          _currentPage == _onboardingData.length - 1 ? "Bắt đầu ngay" : "Tiếp theo",
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
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
