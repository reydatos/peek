import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text(.homeTagline)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                NavigationLink(value: HomeRoute.booth) {
                    Label(.startBooth, systemImage: "camera")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle(Text(.appName))
            .navigationDestination(for: HomeRoute.self) { _ in
                BoothView()
            }
        }
    }
}

#Preview {
    HomeView()
}
