class Product {
  String? prdNo;
  String? prdNom;
  String? prdQr;
  String? uploaded;

  Product({this.prdNo, this.prdNom, this.prdQr});

  Product.fromJson(Map<String, dynamic> json) {
    prdNo = json['prd_no'];
    prdNom = json['prd_nom'];
    prdQr = json['prd_qr'];
    uploaded = (json['prd_qr'] == null || json['prd_qr'] == '') ? '0' : '1';
  }

  Map<String, dynamic> toJson() {
    return {
      'prd_no': prdNo,
      'prd_nom': prdNom,
      'prd_qr': prdQr,
      'uploaded': uploaded,
    };
  }
}
