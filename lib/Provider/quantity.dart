import 'package:flutter/cupertino.dart';

class MyQuantity extends ChangeNotifier{
  int _currenNumber = 1;
  List<double> _baseIngredientAmouts = [];
  int get currentNumber => _currenNumber;
  //set initinal ingredient amounts
  void setInitialIngredientAmounts(List<double> amounts){
    _baseIngredientAmouts = amounts;
    notifyListeners();
  }
  //Update ingredient amounts based on the current number
  Iterable<String> updateIngredientAmounts(){
    return _baseIngredientAmouts
        .map<String>((amount) => (amount * _currenNumber)
        .toStringAsFixed(1)
        .toString());
  }
  //increase saves
  void increaseQuantity(){
    _currenNumber++;
    notifyListeners();
  }
  //decrease saves
  void decreaseQuantity(){
    if(_currenNumber > 1){
      _currenNumber--;
      notifyListeners();
    }

  }
}