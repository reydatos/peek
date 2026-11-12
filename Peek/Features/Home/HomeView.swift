import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text(.homeTagline)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                NavigationLink(value: HomeRoute.booth(packID: PoseLibrary.classicID)) {
                    Label(.startBooth, systemImage: "camera")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                NavigationLink(value: HomeRoute.poseIdeas) {
                    Label(.poseIdeas, systemImage: "figure.wave")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle(Text(.appName))
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case let .booth(packID): BoothView(packID: packID)
                case .poseIdeas: PoseIdeasView()
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
