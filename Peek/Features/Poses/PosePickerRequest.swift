import Foundation

/// The request to show the pose picker. `sheet(item:)` needs an identifiable value.
struct PosePickerRequest: Identifiable {
    let id = UUID()
}
