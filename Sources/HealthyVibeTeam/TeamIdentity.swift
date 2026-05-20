import CryptoKit
import Foundation
import Security

public enum TeamIdentity {
    public static let maxDisplayNameLength = 12

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
            displayName: normalizeDisplayName(displayName)
        )
    }

    public static func generateTeamCode() -> String {
        let value = Int(secureRandomUInt32() % 1_000_000)
        return String(format: "%06d", value)
    }

    public static func normalizeTeamCode(_ code: String) -> String {
        let digits = code.unicodeScalars
            .filter { (48...57).contains($0.value) }
            .map(String.init)
            .joined()
        return String(digits.prefix(6))
    }

    public static func isValidTeamCode(_ code: String) -> Bool {
        normalizeTeamCode(code).count == 6
    }

    public static func normalizeDisplayName(_ displayName: String?) -> String? {
        guard let displayName else {
            return nil
        }

        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return String(trimmed.prefix(maxDisplayNameLength))
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

    private static func secureRandomUInt32() -> UInt32 {
        let bytes = secureRandomBytes(count: 4)
        return bytes.reduce(UInt32(0)) { partial, byte in
            (partial << 8) | UInt32(byte)
        }
    }
}
