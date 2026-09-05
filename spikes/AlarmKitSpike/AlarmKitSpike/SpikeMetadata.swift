import AlarmKit
import Foundation

/// Minimal metadata conforming to AlarmMetadata (required by AlarmAttributes).
struct SpikeMetadata: AlarmMetadata {
    var label: String

    init(label: String = "qiyama-spike") {
        self.label = label
    }
}
