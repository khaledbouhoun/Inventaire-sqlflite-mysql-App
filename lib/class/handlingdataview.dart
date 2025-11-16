import 'package:flutter/material.dart';
import 'package:invontaire_local/class/statusrequest.dart';

class HandlingDataRequest extends StatelessWidget {
  final StatusRequest statusRequest;
  final Widget widget;
  const HandlingDataRequest({super.key, required this.statusRequest, required this.widget});

  @override
  Widget build(BuildContext context) {
    return statusRequest == StatusRequest.loading
        ? Center(child: Text('Loading...'))
        : statusRequest == StatusRequest.offlinefailure
        ? Center(child: Text('Offline'))
        : statusRequest == StatusRequest.serverfailure
        ? Center(child: Text('Server'))
        : widget;
  }
}
