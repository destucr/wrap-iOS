import Foundation
import UIKit

nonisolated enum DriverState: String, Codable, Sendable, Hashable, Equatable {
    case idle = "IDLE"
    case busy = "BUSY"
    case overloaded = "OVERLOADED"
    case offline = "OFFLINE"
    
    var color: UIColor {
        switch self {
        case .idle: return .systemGreen
        case .busy: return .systemOrange
        case .overloaded: return .systemRed
        case .offline: return .systemGray
        }
    }
    
    var bannerText: String {
        switch self {
        case .idle: return "Kilat: 15 Menit"
        case .busy: return "Toko Sedang Ramai"
        case .overloaded: return "Antrean Panjang"
        case .offline: return "Toko Sedang Tutup"
        }
    }
}

nonisolated struct ETAInfo: Codable, Sendable, Hashable, Equatable {
    let etaMins: Int
    let state: DriverState
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case etaMins = "eta_mins"
        case state, message
    }
}
