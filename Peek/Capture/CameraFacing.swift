/// The camera that the booth uses: the rear camera, or the front camera for a group selfie.
nonisolated enum CameraFacing: Sendable {
    case rear
    case front

    var opposite: CameraFacing {
        self == .rear ? .front : .rear
    }
}
