import 'dart:typed_data';
import 'dart:convert';

class CreditCardDetails {
  final dynamic cardNumber;
  final dynamic expiryDate;
  final dynamic cardHolderName;
  final dynamic cvvCode;


  CreditCardDetails(this.cardNumber, this.expiryDate, this.cardHolderName, this.cvvCode);

  CreditCardDetails.fromJson(Map<String, dynamic> json)
      : cardNumber = json['"cardNumber"'] as String,
        expiryDate = json['"expiryDate"'] as String,
        cardHolderName = json['"cardHolderName"'] as String,
        cvvCode = json['"cvvCode"'] as String;

  Map<String, dynamic> toJson() => {
        'cardNumber': cardNumber,
        'expiryDate': expiryDate,
        'cardHolderName': cardHolderName,
        'cvvCode': cvvCode
      };
  Map<String, dynamic> toJsonDB(String id) => {
    'submissionID': id,
    'cardNumber': cardNumber,
    'expiryDate': expiryDate,
    'cardHolderName': cardHolderName,
    'cvvCode': cvvCode
  };

}
