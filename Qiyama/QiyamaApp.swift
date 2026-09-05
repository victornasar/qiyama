import SwiftUI
import UserNotifications

@main
struct QiyamaApp: App {
    @State private var store = AppStore()
    @State private var delegate = NotificationDelegate()

    var body: some Scene {
        WindowGroup {
            Group {
                if !store.ready {
                    ZStack {
                        QiyamaTheme.paper.ignoresSafeArea()
                        ProgressView()
                            .tint(QiyamaTheme.lantern)
                    }
                } else if store.showSetup {
                    SetupView()
                } else if store.showWake {
                    WakeFlowView()
                } else {
                    MainTabView()
                }
            }
            .environment(store)
            .task {
                UNUserNotificationCenter.current().delegate = delegate
                delegate.store = store
                await store.bootstrap()
            }
            .preferredColorScheme(.light)
        }
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    weak var store: AppStore?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let info = response.notification.request.content.userInfo
        guard let type = info["type"] as? String, type == "wake",
              let dateKey = info["dateKey"] as? String
        else { return }
        await MainActor.run {
            store?.handleNotification(dateKey: dateKey)
        }
    }
}
