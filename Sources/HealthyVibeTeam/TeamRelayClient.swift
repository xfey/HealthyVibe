import Foundation

public final class TeamRelayClient {
    private let baseURL: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        baseURL: URL = URL(string: "https://healthyvibe.owlib.ai")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = Self.iso8601WithFractionalSeconds.date(from: value) ?? Self.iso8601.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO8601 date: \(value)"
            )
        }
        self.decoder = decoder
    }

    public func postSnapshot(_ snapshot: TeamSnapshot) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/team/snapshot"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try encoder.encode(snapshot)

        let (_, response) = try await session.data(for: request)
        try validate(response)
    }

    public func fetchRanking(teamCodeHash: String, date: String) async throws -> TeamRanking {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("v1/team/ranking"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "team", value: teamCodeHash),
            URLQueryItem(name: "date", value: date)
        ]

        guard let url = components?.url else {
            throw TeamRelayError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        try validate(response)
        return try decoder.decode(TeamRanking.self, from: data)
    }

    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TeamRelayError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw TeamRelayError.httpStatus(httpResponse.statusCode)
        }
    }
}

private extension TeamRelayClient {
    static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

public enum TeamRelayError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
}
