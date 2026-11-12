nonisolated enum CaptureError: Error, Equatable {
    case permissionDenied
    case cameraUnavailable
    case configurationFailed
    case notRunning
    case captureFailed
}
