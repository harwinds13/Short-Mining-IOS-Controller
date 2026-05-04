import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Add / Set with merge
    func addDocument(collectionName: String, bbCandidateId: String, data: [String: Any]) {
        db.collection(collectionName).document(bbCandidateId).setData(data, merge: true) { error in
            if let error = error {
                print("FirestoreService.addDocument error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Update status field
    func updateStatus(collectionName: String, bbCandidateId: String, newStatus: String) {
        db.collection(collectionName).document(bbCandidateId).updateData(["status": newStatus]) { error in
            if let error = error {
                print("FirestoreService.updateStatus error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Update autoLoginAttempt
    func updateAutoLoginAttempt(
        collectionName: String,
        bbCandidateId: String,
        newAttempt: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        db.collection(collectionName).document(bbCandidateId).updateData(["autoLoginAttempt": newAttempt]) { error in
            completion?(error)
        }
    }

    // MARK: - Retrieve document (cache-first)
    func retrieveDocument(
        collectionName: String,
        bbCandidateId: String,
        completion: @escaping ([String: Any]?) -> Void
    ) {
        let docRef = db.collection(collectionName).document(bbCandidateId)
        docRef.getDocument(source: .cache) { snapshot, error in
            if let data = snapshot?.data(), error == nil {
                completion(data)
            } else {
                docRef.getDocument(source: .server) { snapshot, error in
                    completion(snapshot?.data())
                }
            }
        }
    }

    // MARK: - Save form data
    func saveFormData(
        collectionName: String,
        bbCandidateId: String,
        formData: [String: Any],
        completion: @escaping (Error?) -> Void
    ) {
        db.collection(collectionName).document(bbCandidateId).setData(formData, merge: true) { error in
            completion(error)
        }
    }

    // MARK: - Archive client (read → write to archive → delete from source)
    func archiveClient(
        sourceCollection: String,
        archivedCollection: String,
        bbCandidateId: String,
        completion: @escaping (Error?) -> Void
    ) {
        let sourceRef = db.collection(sourceCollection).document(bbCandidateId)
        let archiveRef = db.collection(archivedCollection).document(bbCandidateId)

        sourceRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                completion(error)
                return
            }
            archiveRef.setData(data, merge: true) { writeError in
                if let writeError = writeError {
                    completion(writeError)
                    return
                }
                sourceRef.delete { deleteError in
                    completion(deleteError)
                }
            }
        }
    }

    // MARK: - Unarchive client (restore from archive → delete from archive)
    func unarchiveClient(
        archivedCollection: String,
        sourceCollection: String,
        bbCandidateId: String,
        completion: @escaping (Error?) -> Void
    ) {
        archiveClient(
            sourceCollection: archivedCollection,
            archivedCollection: sourceCollection,
            bbCandidateId: bbCandidateId,
            completion: completion
        )
    }
}
