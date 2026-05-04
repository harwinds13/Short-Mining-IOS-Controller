import Foundation

final class APIService {
    private let accessToken: String
    private let baseURL = "https://hiring.amazon.ca"

    init(accessToken: String) {
        self.accessToken = accessToken
    }

    private var authHeaders: [String: String] {
        ["Authorization": "Bearer \(accessToken)", "Content-Type": "application/json"]
    }

    private func makeRequest(path: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        guard let url = URL(string: baseURL + path) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        authHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = body
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }

    // MARK: - Query active jobs — returns [(jobId, applicationId)]
    func queryActiveJobs(bbCandidateId: String) async -> [(String, String)]? {
        do {
            let data = try await makeRequest(path: "/api/v1/candidate/\(bbCandidateId)/jobs/active")
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let jobs = json["jobs"] as? [[String: Any]] else { return nil }
            return jobs.compactMap { job -> (String, String)? in
                guard let jobId = job["jobId"] as? String,
                      let appId = job["applicationId"] as? String else { return nil }
                return (jobId, appId)
            }
        } catch {
            print("APIService.queryActiveJobs error: \(error)")
            return nil
        }
    }

    // MARK: - Create application — returns applicationId or "APPLICATION_NOT_CREATED"
    func createApplication(bbCandidateId: String, jobId: String) async -> String {
        do {
            let body = try JSONSerialization.data(withJSONObject: ["jobId": jobId])
            let data = try await makeRequest(
                path: "/api/v1/candidate/\(bbCandidateId)/application",
                method: "POST",
                body: body
            )
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let appId = json["applicationId"] as? String else { return "APPLICATION_NOT_CREATED" }
            return appId
        } catch {
            print("APIService.createApplication error: \(error)")
            return "APPLICATION_NOT_CREATED"
        }
    }

    // MARK: - Query candidate basics — returns (firstName, phoneNumber, emailId)
    func queryCandidate(bbCandidateId: String) async -> (String, String, String)? {
        do {
            let data = try await makeRequest(path: "/api/v1/candidate/\(bbCandidateId)")
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
            let firstName = json["firstName"] as? String ?? ""
            let phone = json["phoneNumber"] as? String ?? ""
            let email = json["emailId"] as? String ?? ""
            return (firstName, phone, email)
        } catch {
            print("APIService.queryCandidate error: \(error)")
            return nil
        }
    }

    // MARK: - Fetch full candidate details
    func fetchCandidateFullDetails(bbCandidateId: String) async -> [String: Any]? {
        do {
            let data = try await makeRequest(path: "/api/v1/candidate/\(bbCandidateId)/full")
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch {
            print("APIService.fetchCandidateFullDetails error: \(error)")
            return nil
        }
    }
}
