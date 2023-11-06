class CreditCardDetails {
  final String cardNumber;
  final String expiryDate;
  final String cardHolderName;
  final String cvvCode;

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
}
