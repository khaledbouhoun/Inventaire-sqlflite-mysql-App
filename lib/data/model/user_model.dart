class User {
  int? usrNo;
  String? usrNom;
  int? usrPntg;
  String? usrPntgNom;
  int? usrLemp;
  String? usrLempNom;

  User({
    this.usrNo,
    this.usrNom,
    this.usrPntg,
    this.usrPntgNom,
    this.usrLemp,
    this.usrLempNom,
  });

  User.fromJson(Map<String, dynamic> json) {
    usrNo = json['usr_no'];
    usrNom = json['usr_nom'];
    usrPntg = json['usr_pntg'];
    usrPntgNom = json['usr_pntg_nom'];
    usrLemp = json['usr_lemp'];
    usrLempNom = json['usr_lemp_nom'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['usr_no'] = usrNo;
    data['usr_nom'] = usrNom;
    data['usr_pntg'] = usrPntg;
    data['usr_pntg_nom'] = usrPntgNom;
    data['usr_lemp'] = usrLemp;
    data['usr_lemp_nom'] = usrLempNom;
    return data;
  }
}
