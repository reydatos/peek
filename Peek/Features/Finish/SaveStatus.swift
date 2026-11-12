/// The result of the last save to Photos, for the finished screen.
enum SaveStatus: Equatable {
    case idle
    case saving
    case saved
    case denied
    case failed
}
