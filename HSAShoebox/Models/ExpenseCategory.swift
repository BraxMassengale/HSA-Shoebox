import Foundation

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case doctor
    case dental
    case vision
    case pharmacy
    case hospital
    case therapy
    case medicalDevice
    case labWork
    case insurance
    case mileage
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .doctor: "Doctor"
        case .dental: "Dental"
        case .vision: "Vision"
        case .pharmacy: "Pharmacy"
        case .hospital: "Hospital"
        case .therapy: "Therapy"
        case .medicalDevice: "Medical Device"
        case .labWork: "Lab Work"
        case .insurance: "Insurance"
        case .mileage: "Mileage"
        case .other: "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .doctor: "stethoscope"
        case .dental: "mouth"
        case .vision: "eye"
        case .pharmacy: "pills"
        case .hospital: "cross.case"
        case .therapy: "figure.mind.and.body"
        case .medicalDevice: "stethoscope.circle"
        case .labWork: "testtube.2"
        case .insurance: "shield.checkered"
        case .mileage: "car"
        case .other: "tray.full"
        }
    }
}
