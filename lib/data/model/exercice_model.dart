class ExerciceModel {
  int? eXENO;
  DateTime? eXEDATEDEB;
  DateTime? eXEDATEFIN;
  int? eXECLOS;

  ExerciceModel({this.eXENO, this.eXEDATEDEB, this.eXEDATEFIN, this.eXECLOS});

  ExerciceModel.fromJson(Map<String, dynamic> json) {
    eXENO = json['EXENO'];
    eXEDATEDEB = DateTime.parse(json['EXEDATEDEB']);
    eXEDATEFIN = DateTime.parse(json['EXEDATEFIN']);
    eXECLOS = json['EXECLOS'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['EXENO'] = eXENO;
    data['EXEDATEDEB'] = eXEDATEDEB;
    data['EXEDATEFIN'] = eXEDATEFIN;
    data['EXECLOS'] = eXECLOS;
    return data;
  }
}
