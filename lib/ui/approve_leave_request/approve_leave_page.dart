import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mm_hrmangement/model/UserModel.dart';
import 'package:flutter_mm_hrmangement/redux/states/app_state.dart';
import 'package:flutter_mm_hrmangement/utility/constants.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:http/http.dart' as http;
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApproveLeavePage extends StatelessWidget {
  final Map<dynamic, dynamic> notificationMessage;

  ApproveLeavePage(this.notificationMessage);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        elevation: 0.0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: new Text(
          (notificationMessage['type'] == 'leave_approved')? "Leave Status": 'Approve Leave',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: buildContent(context),
    );
  }

  Widget buildContent(BuildContext context) {
    return StoreConnector<AppState, _ViewModel>(
        converter: (Store<AppState> store) => _ViewModel.fromStore(store),
        builder: (BuildContext context, _ViewModel viewModel) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          notificationMessage['fromMessage'],
                          style: TextStyle(
                            color: Colors.black87,
                            letterSpacing: 1.2,
                            fontFamily: 'Poppins',
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w600,
                            fontSize: 20.0,
                          ),
                        ),
                      ),

                      getButtonsDependingOnNotificationType(viewModel.user, context),

                    ],
                  ),
                ),
              ),

              Center(child: isLeaveApproved())
            ],
          );
        });
  }

  Widget getButtonsDependingOnNotificationType(User user, BuildContext context) {
    print(notificationMessage['isApproved']);
    if((notificationMessage['type'] == 'leave_approved')) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
              '${notificationMessage['fromName']} has ${(notificationMessage['isApproved'] == 'true') ? 'approved': 'declined'} your leave.',
              style: TextStyle(
                color: (notificationMessage['isApproved'] == 'true') ? Colors.green: Colors.red,
                letterSpacing: 1.2,
                fontFamily: 'Poppins',
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w600,
                fontSize: 20.0,
              )
          ),
        ),
      );
    } else {
      return Container(
          height: 48.0,
          width: double.infinity,
          margin: EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              RaisedButton(
                  elevation: 6.0,
                  shape: new RoundedRectangleBorder(
                      borderRadius:
                      new BorderRadius.circular(30.0)),
                  padding: EdgeInsets.all(16.0),
                  color: Colors.deepOrange,
                  child: Text(
                    'Decline Leave',
                    style: TextStyle(
                        color: Colors.white, fontSize: 16.0),
                  ),
                  onPressed: () {
                    sendNotification(
                        notificationMessage['fromPushId'],
                        user,
                        notificationMessage['fromMessage'],
                        false,
                        notificationMessage['fromId'],
                    context);
                  }),
              RaisedButton(
                  elevation: 6.0,
                  shape: new RoundedRectangleBorder(
                      borderRadius:
                      new BorderRadius.circular(30.0)),
                  padding: EdgeInsets.all(16.0),
                  color: Colors.blueGrey,
                  child: Text(
                    'Approve Leave',
                    style: TextStyle(
                        color: Colors.white, fontSize: 16.0),
                  ),
                  onPressed: () {
                    sendNotification(
                        notificationMessage['fromPushId'],
                        user,
                        notificationMessage['fromMessage'],
                        true,
                        notificationMessage['fromId'],context);
                  }),
            ],
          )
      );
    }
  }



  Widget isLeaveApproved() {
    if(notificationMessage['type'] == 'leave_approved' && notificationMessage['isApproved'] == 'true') {
      return Container(
        width: 200.0,
        height: 200.0,
        decoration: new BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.shade100,
          image: DecorationImage(
            image: new ExactAssetImage('assets/tick.png'),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Center();
    }
  }
}


void sendNotification(
    String sendingToken,
    User user,
    String message,
    bool isApproved,
    String leaveId, BuildContext context) async {

  Firestore.instance.runTransaction((Transaction transaction) async {
    await Firestore.instance.collection('leaveCollection').document(leaveId).updateData({
      "status": isApproved ? 1 : 2,
    });
  });
  
  
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var fcm_token = prefs.getString(FIREBASE_FCM_TOKEN);
  var base = 'https://us-central1-mm-leavemanagement.cloudfunctions.net/';
  String dataURL = '$base/sendNotification?'
      'to=${sendingToken}'
      '&fromPushId=$fcm_token'
      '&fromId=$leaveId'
      '&fromName=${user.name}'
      '&fromMessage=$message'
      '&isApproved=$isApproved'
      '&type=leave_approved';
  print(dataURL);
  await http.get(dataURL).then((response) {});

  Navigator.pop(context);
}



class _ViewModel {
  final User user;

  _ViewModel({
    @required this.user,
  });

  static _ViewModel fromStore(Store<AppState> store) {
    return new _ViewModel(user: store.state.loginState.user);
  }
}
