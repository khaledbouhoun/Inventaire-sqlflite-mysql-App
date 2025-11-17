class ArticlesModel {
  String? artno;
  String? artnom;
  String? artref;
  String? artref2;
  String? artref3;
  int? artvtepar;
  int? artpap;
  int? artcompo2;

  String? artcolis;
  String? artcab;
  String? artcab2;
  String? artcab3;
  String? artcab4;
  String? artcab5;
  String? artcab6;
  String? artcab7;
  String? artcab8;
  String? artcab9;
  String? artcab10;

  ArticlesModel({
    this.artno,
    this.artnom,
    this.artref,
    this.artref2,
    this.artref3,
    this.artvtepar,
    this.artcolis,
    this.artcompo2,
    this.artpap,
    this.artcab,
    this.artcab2,
    this.artcab3,
    this.artcab4,
    this.artcab5,
    this.artcab6,
    this.artcab7,
    this.artcab8,
    this.artcab9,
    this.artcab10,
  });

  ArticlesModel.fromJson(Map<String, dynamic> json) {
    artno = json['artno'];
    artnom = json['artnom'];
    artref = json['artref'];
    artref2 = json['artref2'];
    artref3 = json['artref3'];
    artvtepar = (json['artvtepar'] as num?)?.toInt();
    artcompo2 = (json['artcompo2'] as num?)?.toInt();
    artcolis = json['artcolis'];
    artpap = (json['artpap'] as num?)?.toInt();
    artcab = json['artcab'];
    artcab2 = json['artcab2'];
    artcab3 = json['artcab3'];
    artcab4 = json['artcab4'];
    artcab5 = json['artcab5'];
    artcab6 = json['artcab6'];
    artcab7 = json['artcab7'];
    artcab8 = json['artcab8'];
    artcab9 = json['artcab9'];
    artcab10 = json['artcab10'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['artno'] = artno;
    data['artnom'] = artnom;
    data['artref'] = artref;
    data['artref2'] = artref2;
    data['artref3'] = artref3;
    data['artvtepar'] = artvtepar;
    data['artcompo2'] = artcompo2;
    data['artcolis'] = artcolis;
    data['artpap'] = artpap;
    data['artcab'] = artcab;
    data['artcab2'] = artcab2;
    data['artcab3'] = artcab3;
    data['artcab4'] = artcab4;
    data['artcab5'] = artcab5;
    data['artcab6'] = artcab6;
    data['artcab7'] = artcab7;
    data['artcab8'] = artcab8;
    data['artcab9'] = artcab9;
    data['artcab10'] = artcab10;
    return data;
  }
}

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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['prd_no'] = prdNo;
    data['prd_nom'] = prdNom;
    data['prd_qr'] = prdQr;
    data['uploaded'] = uploaded;
    return data;
  }
}
