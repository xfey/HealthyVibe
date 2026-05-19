import CryptoKit
import Foundation
import Security

public enum TeamIdentity {
    private static let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    public static func makeProfile(
        teamCode: String,
        memberID: String = UUID().uuidString,
        displayName: String?
    ) -> TeamProfile {
        let normalizedCode = normalizeTeamCode(teamCode)
        return TeamProfile(
            teamCode: normalizedCode,
            teamCodeHash: sha256Hex(normalizedCode),
            memberID: memberID,
            memberIDHash: sha256Hex(memberID),
            displayName: displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    public static func generateTeamCode(byteCount: Int = 12) -> String {
        let bytes = secureRandomBytes(count: byteCount)
        let characters = bytes.map { alphabet[Int($0) % alphabet.count] }
        return stride(from: 0, to: characters.count, by: 4)
            .map { String(characters[$0..<min($0 + 4, characters.count)]) }
            .joined(separator: "-")
    }

    public static func normalizeTeamCode(_ code: String) -> String {
        code
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }
            .chunked(size: 4)
            .joined(separator: "-")
    }

    public static func sha256Hex(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func secureRandomBytes(count: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status == errSecSuccess {
            return bytes
        }

        return (0..<count).map { _ in UInt8.random(in: UInt8.min...UInt8.max) }
    }
}

private extension String {
    func chunked(size: Int) -> [String] {
        var chunks: [String] = []
        var index = startIndex

        while index < endIndex {
            let end = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            chunks.append(String(self[index..<end]))
            index = end
        }

        return chunks
    }
}
