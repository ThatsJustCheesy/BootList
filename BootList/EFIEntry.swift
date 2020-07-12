import Foundation

struct EFIEntry: Identifiable {
    var id: UInt
    var label: String

    var formattedID: String {
        String(format: "%04x", id)
    }
}
