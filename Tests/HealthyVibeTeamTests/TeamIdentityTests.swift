import XCTest
@testable import HealthyVibeTeam

final class TeamIdentityTests: XCTestCase {
    func testNormalizesTeamCodeAndHashesIdentity() {
        let profile = TeamIdentity.makeProfile(
            teamCode: "12 34-56",
            memberID: "member-1",
            displayName: " xfey "
        )

        XCTAssertEqual(profile.teamCode, "123456")
        XCTAssertEqual(profile.displayName, "xfey")
        XCTAssertEqual(profile.teamCodeHash.count, 64)
        XCTAssertEqual(profile.memberIDHash.count, 64)
        XCTAssertTrue(TeamIdentity.isValidTeamCode("123456"))
        XCTAssertFalse(TeamIdentity.isValidTeamCode("12345"))
    }

    func testGeneratedTeamCodeIsShareable() {
        let code = TeamIdentity.generateTeamCode()
        XCTAssertEqual(code.count, 6)
        XCTAssertTrue(code.allSatisfy(\.isNumber))
    }
}

final class TeamRelayClientTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    func testFetchRankingDecodesCloudflareIsoDates() async throws {
        MockURLProtocol.handler = { request in
            let data = """
            {
              "teamCodeHash": "team-hash",
              "date": "2026-05-19",
              "generatedAt": "2026-05-19T12:00:00.000Z",
              "members": [
                {
                  "rank": 1,
                  "memberIdHash": "member-hash",
                  "displayName": "xfey",
                  "longevityMinutes": 20,
                  "completedTaskCount": 6,
                  "updatedAt": "2026-05-19T12:00:00.123Z"
                }
              ]
            }
            """.data(using: .utf8)!

            return (
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["content-type": "application/json"]
                )!,
                data
            )
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = TeamRelayClient(
            baseURL: URL(string: "https://relay.example")!,
            session: session
        )

        let ranking = try await client.fetchRanking(teamCodeHash: "team-hash", date: "2026-05-19")
        let member = try XCTUnwrap(ranking.members.first)

        XCTAssertEqual(member.rank, 1)
        XCTAssertEqual(member.updatedAt.timeIntervalSince1970, 1_779_192_000.123, accuracy: 0.001)
    }
}

private final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
