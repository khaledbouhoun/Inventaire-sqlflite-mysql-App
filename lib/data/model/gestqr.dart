class GestQr {
  int? gqrNo;
  int? gqrLempNo;
  int? gqrUsrNo;
  String? gqrPrdNo;
  DateTime? gqrDate;
  int? isUploaded;

  GestQr({this.gqrNo, this.gqrLempNo, this.gqrUsrNo, this.gqrPrdNo, this.gqrDate, this.isUploaded});

  GestQr.fromJson(Map<String, dynamic> json) {
    gqrNo = json['gqr_no'];
    gqrLempNo = json['gqr_lemp_no'];
    gqrUsrNo = json['gqr_usr_no'];
    gqrPrdNo = json['gqr_prd_no'];
    gqrDate = DateTime.parse(json['gqr_date']);
    isUploaded = gqrNo == null ? 0 : 1;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['gqr_no'] = gqrNo;
    data['gqr_lemp_no'] = gqrLempNo;
    data['gqr_usr_no'] = gqrUsrNo;
    data['gqr_prd_no'] = gqrPrdNo;
    data['gqr_date'] = gqrDate?.toIso8601String();
    data['is_uploaded'] = isUploaded;
    return data;
  }
}
