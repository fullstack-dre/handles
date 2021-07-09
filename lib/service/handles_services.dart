part of "services.dart";

class HandlesServices with ChangeNotifier{
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  bool isLoading = false;
  HandlesServices({required this.auth, required this.firestore, required this.storage});

  Future<UserModel?> addMember(String phoneNumber) async {
    UserModel? userModelOutput;
    try{
      await firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .get()
        .then((value){
          var user = value.docs.first;
          userModelOutput = UserModel(
            id: user.id,
            countryCode: user["countryCode"],
            name: user["name"],
            profilePicture: user["profilePicture"],
            phoneNumber: user["phoneNumber"],
            role: user["role"],
            company: user["company"],
            companyAddress: user["companyAddress"],
            companyLogo: user["companyLogo"],
            creditCard: user["creditCard"],
            handlesList: (user["handlesList"] as List<dynamic>).cast<String>(),
          );
        }
      );
    } catch (e){
      print(e);
      notifyListeners();
    }

    return userModelOutput;
  }

  Future<void> createHandles(HandlesModel handlesModel) async {
    await firestore
      .collection('handles')
      .doc(handlesModel.id)
      .set({
        "name": handlesModel.name,
        "description": handlesModel.description,
        "cover": handlesModel.cover,
        "members": handlesModel.members,
        "pinnedBy": handlesModel.pinnedBy,
        "archivedBy": handlesModel.archivedBy
      }
    ).then((value){
      handlesModel.members.forEach((element) {
        firestore
          .collection('users')
          .doc(element)
          .get().then((value){

            List<dynamic> oldHandlesList = (value["handlesList"] as List<dynamic>);
            oldHandlesList.add(handlesModel.id);

            firestore.collection('users')
            .doc(element)
            .update({
              "handlesList": oldHandlesList
            });
        });
      });
    });
  }

  Future<void> deleteHandles(List<String> selectedHandles) async{
    selectedHandles.forEach((targetHandlesUID) {
      firestore
      .collection("handles")
      .doc(targetHandlesUID)
      .get().then((value){
        List<dynamic> oldMemberList = (value["members"] as List<dynamic>);
        oldMemberList.remove(auth.currentUser!.uid);

        firestore
        .collection("handles")
        .doc(targetHandlesUID)
        .update({
          "members": oldMemberList
        });
      }).then((value){
        firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .get().then((value){
          List<dynamic> oldHandlesList = (value["handlesList"] as List<dynamic>);
          oldHandlesList.remove(targetHandlesUID);

          firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .update({
            "handlesList": oldHandlesList
          });
        });
      });
    });
  }

  Future<String?> uploadHandlesCover(String filePath, String handlesName) async {

    String? outputURL;
    File file = File(filePath);
    try {
      await storage
      .ref('handles_cover/$handlesName.png')
      .putFile(file);

      String downloadURL = await FirebaseStorage.instance
        .ref('handles_cover/$handlesName.png')
        .getDownloadURL();

      outputURL = downloadURL;
    } on FirebaseException catch (e) {
      print(e.toString());
    }

    return outputURL;
  }

  Future<void> pinHandles(List<String> handlesList) async {
    return handlesList.forEach((uid) {
      firestore
      .collection("handles")
      .doc(uid)
      .get().then((value){
        List<dynamic> oldPinnedByList = (value["pinnedBy"] as List<dynamic>);
        oldPinnedByList.add(auth.currentUser!.uid);

        firestore
        .collection("handles")
        .doc(uid)
        .update({
          "pinnedBy": oldPinnedByList
        });
      });
    });
  }

  Future<void> archiveHandles(List<String> handlesList) async {
    return handlesList.forEach((uid) {
      firestore
      .collection("handles")
      .doc(uid)
      .get().then((value){
        List<dynamic> oldArchivedHandlesList = (value["archivedBy"] as List<dynamic>);
        oldArchivedHandlesList.add(auth.currentUser!.uid);

        firestore
        .collection("handles")
        .doc(uid)
        .update({
          "archivedBy": oldArchivedHandlesList
        });
      });
    });
  }

  Future<void> unpinHandles(List<String> handlesList) async {
    return handlesList.forEach((uid) {
      firestore
      .collection("handles")
      .doc(uid)
      .get().then((value){
        List<dynamic> oldArchivedHandlesList = (value["pinnedBy"] as List<dynamic>);
        oldArchivedHandlesList.remove(auth.currentUser!.uid);

        firestore
        .collection("handles")
        .doc(uid)
        .update({
          "pinnedBy": oldArchivedHandlesList
        });
      });
    });
  }

  Future<void> unarchiveHandles(List<String> handlesList) async {
    return handlesList.forEach((uid) {
      firestore
      .collection("handles")
      .doc(uid)
      .get().then((value){
        List<dynamic> oldArchivedHandlesList = (value["archivedBy"] as List<dynamic>);
        oldArchivedHandlesList.remove(auth.currentUser!.uid);

        print(oldArchivedHandlesList);

        firestore
        .collection("handles")
        .doc(uid)
        .update({
          "archivedBy": oldArchivedHandlesList
        });
      });
    });
  }

  Stream<HandlesModel> handlesModelGetter(String handlesID){
    return firestore
      .collection("handles")
      .doc(handlesID)
      .snapshots()
      .map(_eventModelListMapper);
  }

 HandlesModel _eventModelListMapper(DocumentSnapshot snapshot){
    HandlesModel out = HandlesModel(
      id: snapshot.id,
      description: snapshot['description'],
      members: (snapshot['members'] as List<dynamic>).cast<String>(),
      name: snapshot['name'],
      cover: snapshot['cover'],
      pinnedBy: (snapshot['pinnedBy'] as List<dynamic>).cast<String>(),
      archivedBy: (snapshot['archivedBy'] as List<dynamic>).cast<String>(),
    );
    return out;
  }
}