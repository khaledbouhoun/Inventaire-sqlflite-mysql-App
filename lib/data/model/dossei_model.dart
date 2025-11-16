class DossierModel {
  // String? basesys;
  String? dosNo;
  String? dosNom;
  String? dosBdd;

  DossierModel({this.dosNo, this.dosNom});

  DossierModel.fromJson(Map<String, dynamic> json) {
    // basesys = json['BaseSys'];
    dosNo = json['DosNo'];
    dosNom = json['DosNom'];
    dosBdd = json['DOSBDD'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    // data['BaseSys'] = basesys;
    data['DosNo'] = dosNo;
    data['DosNom'] = dosNom;
    data['DOSBDD'] = dosBdd;
    return data;
  }
}
