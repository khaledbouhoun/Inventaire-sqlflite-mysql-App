class InventairedModel {
  DateTime? iNDDATE;
  String? iNDNO;
  String? iNDART;
  String? iNDARTNom;
  int? iNDORD;
  int? iNDCOMPAR;
  double? iNDLONG;
  double? iNDLARG;
  String? iNDCOLISAGE;
  double? iNDCOLIS;
  double? iNDUNTCOL;
  double? iNDQTEINV;
  double? iNDQTETHEOR;
  double? iNDQTEDIFF;
  double? iNDPU;
  double? iNDMONTANT;
  String? iNDQTEEXPR;
  String? iNDDEPOT;
  double? iNDMNTTHEOR;
  double? iNDMNTDIFF;
  double? iNDQTEINVG;
  String? iNDUSER;
  DateTime? iNDDH;

  InventairedModel({
    this.iNDDATE,
    this.iNDNO,
    this.iNDART,
    this.iNDORD,
    this.iNDCOMPAR,
    this.iNDLONG,
    this.iNDLARG,
    this.iNDCOLISAGE,
    this.iNDCOLIS,
    this.iNDUNTCOL,
    this.iNDQTEINV,
    this.iNDQTETHEOR,
    this.iNDQTEDIFF,
    this.iNDPU,
    this.iNDMONTANT,
    this.iNDQTEEXPR,
    this.iNDDEPOT,
    this.iNDMNTTHEOR,
    this.iNDMNTDIFF,
    this.iNDQTEINVG,
    this.iNDUSER,
    this.iNDDH,
  });

  InventairedModel.fromJson(Map<String, dynamic> json) {
    iNDDATE = DateTime.parse(json['INDDATE']);
    iNDNO = json['INDNO'];
    iNDARTNom = "unknown";
    iNDART = json['INDART'];
    iNDORD = (json['INDORD'] as num?)?.toInt();
    iNDCOMPAR = (json['INDCOMPAR'] as num?)?.toInt();
    iNDLONG = (json['INDLONG'] as num?)?.toDouble();
    iNDLARG = (json['INDLARG'] as num?)?.toDouble();
    iNDCOLISAGE = json['INDCOLISAGE'];
    iNDCOLIS = (json['INDCOLIS'] as num?)?.toDouble();
    iNDUNTCOL = (json['INDUNTCOL'] as num?)?.toDouble();
    iNDQTEINV = (json['INDQTEINV'] as num?)?.toDouble();
    iNDQTETHEOR = (json['INDQTETHEOR'] as num?)?.toDouble();
    iNDQTEDIFF = (json['INDQTEDIFF'] as num?)?.toDouble();
    iNDPU = (json['INDPU'] as num?)?.toDouble();
    iNDMONTANT = (json['INDMONTANT'] as num?)?.toDouble();
    iNDQTEEXPR = json['INDQTEEXPR'];
    iNDDEPOT = json['INDDEPOT'];
    iNDMNTTHEOR = (json['INDMNTTHEOR'] as num?)?.toDouble();
    iNDMNTDIFF = (json['INDMNTDIFF'] as num?)?.toDouble();
    iNDQTEINVG = (json['INDQTEINVG'] as num?)?.toDouble();
    iNDUSER = json['INDUSER'];
    iNDDH = DateTime.parse(json['INDDH']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['INDDATE'] = toiso(iNDDATE!);
    data['INDNO'] = iNDNO;
    data['INDART'] = iNDART;
    data['INDORD'] = iNDORD;
    data['INDCOMPAR'] = iNDCOMPAR;
    data['INDLONG'] = iNDLONG;
    data['INDLARG'] = iNDLARG;
    data['INDCOLISAGE'] = iNDCOLISAGE;
    data['INDCOLIS'] = iNDCOLIS;
    data['INDUNTCOL'] = iNDUNTCOL;
    data['INDQTEINV'] = iNDQTEINV;
    data['INDQTETHEOR'] = iNDQTETHEOR;
    data['INDQTEDIFF'] = iNDQTEDIFF;
    data['INDPU'] = iNDPU;
    data['INDMONTANT'] = iNDMONTANT;
    data['INDQTEEXPR'] = iNDQTEEXPR;
    data['INDDEPOT'] = iNDDEPOT;
    data['INDMNTTHEOR'] = iNDMNTTHEOR;
    data['INDMNTDIFF'] = iNDMNTDIFF;
    data['INDQTEINVG'] = iNDQTEINVG;
    data['INDUSER'] = iNDUSER;
    data['INDDH'] = toiso(iNDDH!);
    return data;
  }

  String toiso(DateTime date) {
    // Format: 2022-05-23T00:00:00.000Z
    String formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T"
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}Z";
    return formattedDate;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InventairedModel && other.iNDART == iNDART && other.iNDNO == iNDNO;
  }

  @override
  int get hashCode => iNDART.hashCode ^ iNDNO.hashCode;
}
