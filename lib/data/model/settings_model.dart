class BuySettings {
  int? prmCalculPrixTTC;

  BuySettings({this.prmCalculPrixTTC});

  BuySettings.fromJson(Map<String, dynamic> json) {
    prmCalculPrixTTC = json['PrmCalculPrixTTC'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['PrmCalculPrixTTC'] = prmCalculPrixTTC;
    return data;
  }
}

class SellSettings {
  int? pRMMAJSTK;
  int? pRMCONSOMMATPREM2;
  String? pRMDEPOTDEFAUTTOURNEEAB;

  SellSettings({this.pRMMAJSTK, this.pRMCONSOMMATPREM2, this.pRMDEPOTDEFAUTTOURNEEAB});

  SellSettings.fromJson(Map<String, dynamic> json) {
    pRMMAJSTK = json['PRMMAJSTK'];
    pRMCONSOMMATPREM2 = json['PRMCONSOMMATPREM2'];
    pRMDEPOTDEFAUTTOURNEEAB = json['PRMDEPOTDEFAUTTOURNEEAB'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['PRMMAJSTK'] = pRMMAJSTK;
    data['PRMCONSOMMATPREM2'] = pRMCONSOMMATPREM2;
    data['PRMDEPOTDEFAUTTOURNEEAB'] = pRMDEPOTDEFAUTTOURNEEAB;
    return data;
  }
}
