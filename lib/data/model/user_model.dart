class UserModel {
  String? userId;
  String? userLogin;
  String? userPass;
  String? usernom;
  String? userprenom;

  UserModel({this.userId, this.userLogin, this.userPass});

  UserModel.fromJson(Map<String, dynamic> json) {
    userId = json['UsrNo'];
    usernom = json['USRNOM'];
    userprenom = json['USRPRENOM'];
    userLogin = json['USRLOGIN'];
    userPass = json['UsrPassw'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['UsrNo'] = userId;
    data['USRNOM'] = usernom;
    data['USRPRENOM'] = userprenom;
    data['USRLOGIN'] = userLogin;
    data['UsrPassw'] = userPass;
    return data;
  }
}

class User {
  int? usrId;
  String? usrNom;
  String? usrPntg;
  String? usrDpot;

  User({this.usrId, this.usrNom, this.usrPntg, this.usrDpot});

  User.fromJson(Map<String, dynamic> json) {
    usrId = json['usr_id'];
    usrNom = json['usr_nom'];
    usrPntg = json['usr_pntg'];
    usrDpot = json['usr_dpot'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['usr_id'] = usrId;
    data['usr_nom'] = usrNom;
    data['usr_pntg'] = usrPntg;
    data['usr_dpot'] = usrDpot;
    return data;
  }
}
