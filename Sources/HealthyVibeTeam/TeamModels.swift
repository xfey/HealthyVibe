import Foundation

public struct TeamProfile: Codable, Equatable {
    public let teamCode: String
    public let teamCodeHash: String
    public let memberID: String
    public let memberIDHash: String
    public let displayName: String?

    public init(
        teamCode: String,
        teamCodeHash: String,
        memberID: String,
        memberIDHash: String,
        displayName: String?
    ) {
        self.teamCode = teamCode
        self.teamCodeHash = teamCodeHash
        self.memberID = memberID
        self.memberIDHash = memberIDHash
        self.displayName = displayName
    }
}

public struct TeamSnapshot: Codable, Equatable {
    public let teamCodeHash: String
    public let memberIdHash: String
    public let displayName: String?
    public let date: String
    public let longevityMinutes: Int
    public let completedTaskCount: Int
    public let updatedAt: Date

    public init(
        teamCodeHash: String,
        memberIdHash: String,
        displayName: String?,
        date: String,
        longevityMinutes: Int,
        completedTaskCount: Int,
        updatedAt: Date
    ) {
        self.teamCodeHash = teamCodeHash
        self.memberIdHash = memberIdHash
        self.displayName = displayName
        self.date = date
        self.longevityMinutes = longevityMinutes
        self.completedTaskCount = completedTaskCount
        self.updatedAt = updatedAt
    }
}

public struct TeamRanking: Codable, Equatable {
    public let teamCodeHash: String
    public let date: String
    public let generatedAt: Date
    public let members: [TeamRankingMember]

    public init(
        teamCodeHash: String,
        date: String,
        generatedAt: Date,
        members: [TeamRankingMember]
    ) {
        self.teamCodeHash = teamCodeHash
        self.date = date
        self.generatedAt = generatedAt
        self.members = members
    }

    public func rank(for memberIDHash: String) -> Int? {
        members.first { $0.memberIdHash == memberIDHash }?.rank
    }
}

public struct TeamRankingMember: Codable, Equatable, Identifiable {
    public var id: String { memberIdHash }

    public let rank: Int
    public let memberIdHash: String
    public let displayName: String?
    public let longevityMinutes: Int
    public let completedTaskCount: Int
    public let updatedAt: Date

    public init(
        rank: Int,
        memberIdHash: String,
        displayName: String?,
        longevityMinutes: Int,
        completedTaskCount: Int,
        updatedAt: Date
    ) {
        self.rank = rank
        self.memberIdHash = memberIdHash
        self.displayName = displayName
        self.longevityMinutes = longevityMinutes
        self.completedTaskCount = completedTaskCount
        self.updatedAt = updatedAt
    }
}
