enum CameraStatus: Equatable {
    case idle
    case starting
    case running
    case denied
    case unavailable
    case failed

    init(_ error: CaptureError) {
        switch error {
        case .permissionDenied: self = .denied
        case .cameraUnavailable: self = .unavailable
        case .configurationFailed, .notRunning, .captureFailed: self = .failed
        }
    }
}
