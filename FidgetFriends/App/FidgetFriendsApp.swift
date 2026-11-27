import SwiftUI

@main
struct FidgetFriendsApp: App {
    @StateObject private var store = AppStore.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
