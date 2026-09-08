import Foundation
import Supabase

enum GenerationFeature: String, Encodable {
    case textAI = "text_ai"
    case photoAI = "photo_ai"
}

enum GenerationAccessError: Error {
    case limitReached
    case offline
}

/// The single client-side entry point for server-owned generation usage decisions.
/// It deliberately sends only the feature; entitlement and counters are resolved by the server.
@MainActor final class GenerationAccessService {
    private let client: SupabaseClient
    private let functionURL: URL
    private let apiKey: String

    init(client: SupabaseClient, supabaseURL: URL, apiKey: String) {
        self.client = client
        self.functionURL = supabaseURL.appending(path: "functions/v1/generation-access")
        self.apiKey = apiKey
    }

    func authorize(_ feature: GenerationFeature) async throws {
        do {
            let session: Session
            if let current = try? await client.auth.session {
                session = current
            } else {
                session = try await client.auth.signInAnonymously()
            }

            var request = URLRequest(url: functionURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(["feature": feature.rawValue])

            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw GenerationAccessError.offline }
            if http.statusCode == 429 { throw GenerationAccessError.limitReached }
            guard (200..<300).contains(http.statusCode) else { throw GenerationAccessError.offline }
        } catch let error as GenerationAccessError {
            throw error
        } catch {
            throw GenerationAccessError.offline
        }
    }
}
