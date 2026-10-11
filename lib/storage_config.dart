/// Toggles between Firebase Storage and base64 in Firestore image handling.
/// true  -  use Firebase Storage
/// false -  use base64 strings stored in Firestore
class StorageConfig {
  StorageConfig._();

  static const useFirebaseStorage = false;
}