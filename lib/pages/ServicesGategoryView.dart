import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/*void main() => runApp(new MaterialApp(
  home: new HomePage(),
  debugShowCheckedModeBanner: false,
));*/

class MyApp extends StatefulWidget {
  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<MyApp> {
  TextEditingController controller = new TextEditingController();

  // Get json result and convert it to model. Then add
  Future<Null> getUserDetails() async {
    final response = await http.get(url);
    final responseJson = json.decode(response.body);

    setState(() {
      for (Map user in responseJson) {
        _userDetails.add(UserDetails.fromJson(user));
      }
    });
  }

  @override
  void initState() {
    super.initState();

    /*   getUserDetails();*/
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Home'),
        elevation: 0.0,
      ),
      body: new Column(
        children: <Widget>[
          new Container(
            color: Theme.of(context).primaryColor,
            child: new Padding(
              padding: const EdgeInsets.all(8.0),
              child: new Card(
                child: new ListTile(
                  leading: new Icon(Icons.search),
                  title: new TextField(
                    controller: controller,
                    decoration: new InputDecoration(
                        hintText: 'Search', border: InputBorder.none),
                    onChanged: onSearchTextChanged,
                  ),
                  trailing: new IconButton(
                    icon: new Icon(Icons.cancel),
                    onPressed: () {
                      controller.clear();
                      onSearchTextChanged('');
                    },
                  ),
                ),
              ),
            ),
          ),
          new Expanded(
            child: _searchResult.length != 0 || controller.text.isNotEmpty
                ? new ListView.builder(
                    itemCount: _searchResult.length,
                    itemBuilder: (context, i) {
                      return new Card(
                        child: new ListTile(
                          leading: new CircleAvatar(
                            backgroundImage: new NetworkImage(
                              _searchResult[i].name,
                            ),
                          ),
                          title: new Text(_searchResult[i].name +
                              ' ' +
                              _searchResult[i].name),
                        ),
                        margin: const EdgeInsets.all(0.0),
                      );
                    },
                  )
                : new StreamBuilder(
                    stream: Firestore.instance.collection('service').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text('Loading...');
                      return new ListView.builder(
                        itemCount: snapshot.data.documents.length,
                        padding: const EdgeInsets.only(top: 10.0),
                        itemExtent: 55.0,
                        itemBuilder: (context, index) => _buildListItem(
                            context, snapshot.data.documents[index]),
                      );
                    }),

            /*   : new ListView.builder(
              itemCount: _userDetails.length,
              itemBuilder: (context, index) {
                return new Card(
                  child: new ListTile(
                    leading: new CircleAvatar(backgroundImage: new NetworkImage(_userDetails[index].profileUrl,),),
                    title: new Text(_userDetails[index].firstName + ' ' + _userDetails[index].lastName),
                  ),
                  margin: const EdgeInsets.all(0.0),
                );
              },
            ),*/
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    if(_services.isEmpty) {
      _services.add(new Service(document.documentID, document['name']));
    } else {
      var source = _services.toList();
      var exists = false;
      source.forEach((service) {
        if (service.id.compareTo(document.documentID) == 0){
          exists = true;
        }
      });
      if (!exists)
        _services.add(new Service(document.documentID, document.data['name']));
    }
    return new ListTile(
      key: new ValueKey(document.documentID),
      title: new Container(
        decoration: new BoxDecoration(
          border: new Border.all(color: const Color(0x80000000)),
          borderRadius: new BorderRadius.circular(5.0),
        ),
        padding: const EdgeInsets.all(10.0),
        child: new Row(
          children: <Widget>[
            new Expanded(
              child: new Text(document['name']),
            ),
            new Text(
              document.documentID.toString(),
            ),
          ],
        ),
      ),
      onTap: () => Firestore.instance.runTransaction((transaction) async {
            DocumentSnapshot freshSnap =
                await transaction.get(document.reference);
            await transaction
                .update(freshSnap.reference, {'votes': freshSnap['votes'] + 1});
          }),
    );
  }

  onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    _services.forEach((service) {
      if (service.name.contains(text))
        _searchResult.add(service);
    });

    setState(() {});
  }
}

List<Service> _searchResult = [];

List<UserDetails> _userDetails = [];

List<Service> _services = [];


final String url = 'https://jsonplaceholder.typicode.com/users';

class Service {
  final String id;
  final String name;

  Service(
      this.id,
        this.name
        );

/*  factory Service.fromJson(Map<String, dynamic> json) {
    return new Service(
      id: json['id'],
      name: json['name'],
    );
  }*/
}

class UserDetails {
  final int id;
  final String firstName, lastName, profileUrl;

  UserDetails(
      {this.id,
      this.firstName,
      this.lastName,
      this.profileUrl =
          'https://i.amz.mshcdn.com/3NbrfEiECotKyhcUhgPJHbrL7zM=/950x534/filters:quality(90)/2014%2F06%2F02%2Fc0%2Fzuckheadsho.a33d0.jpg'});

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return new UserDetails(
      id: json['id'],
      firstName: json['name'],
      lastName: json['username'],
    );
  }
}
