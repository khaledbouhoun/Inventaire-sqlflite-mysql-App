class InventaireEnteteModel {
  String? ineno;
  String? inedepot;
  int? inetypecout;
  DateTime? inedate;

  InventaireEnteteModel({this.ineno, this.inedate, this.inedepot});

  InventaireEnteteModel.fromJson(Map<String, dynamic> json) {
    ineno = json['ineno'];
    inedepot = json['inedepot'];
    inetypecout = (json['inetypecout'] as num?)?.toInt();
    inedate = DateTime.tryParse(json['inedate']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ineno'] = ineno;
    data['inedepot'] = inedepot;
    data['inedate'] = inedate;
    return data;
  }
}
