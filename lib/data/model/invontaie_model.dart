class Invontaie {
  int? invNo;
  int? invLempNo;
  String? invLempNom;
  int? invPntgNo;
  String? invPntgNom;
  int? invUsrNo;
  String? invUsrNom;
  String? invPrdNo;
  String? invPrdNom;
  String? invExp;
  DateTime? invDate;
  int? isUploaded; // 0 = pending, 1 = uploaded

  Invontaie({
    this.invNo,
    this.invLempNo,
    this.invLempNom,
    this.invPntgNo,
    this.invPntgNom,
    this.invUsrNo,
    this.invUsrNom,
    this.invPrdNo,
    this.invPrdNom,
    this.invExp,
    this.invDate,
    this.isUploaded,
  });

  Invontaie.fromJson(Map<String, dynamic> json) {
    invNo = json['inv_no'];
    invLempNo = json['inv_lemp_no'];
    invLempNom = json['inv_lemp_nom'];
    invPntgNo = json['inv_pntg_no'];
    invPntgNom = json['inv_pntg_nom'];
    invUsrNo = json['inv_usr_no'];
    invUsrNom = json['inv_usr_nom'];
    invPrdNo = json['inv_prd_no'];
    invPrdNom = json['inv_prd_nom'];
    invExp = json['inv_exp'];
    invDate = json['inv_date'] != null
        ? DateTime.parse(json['inv_date'])
        : null;
    isUploaded = 1; // Default to uploaded for server data
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['inv_no'] = invNo;
    data['inv_lemp_no'] = invLempNo;
    data['inv_lemp_nom'] = invLempNom;
    data['inv_pntg_no'] = invPntgNo;
    data['inv_pntg_nom'] = invPntgNom;
    data['inv_usr_no'] = invUsrNo;
    data['inv_usr_nom'] = invUsrNom;
    data['inv_prd_no'] = invPrdNo;
    data['inv_prd_nom'] = invPrdNom;
    data['inv_exp'] = invExp;
    data['inv_date'] = invDate?.toIso8601String(); // Convert DateTime to String
    data['is_uploaded'] = isUploaded;
    return data;
  }
}
