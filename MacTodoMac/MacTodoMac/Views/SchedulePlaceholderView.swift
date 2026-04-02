import SwiftUI

struct SchedulePlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Schedule",
            systemImage: "calendar.badge.clock",
            description: Text("Coming soon.")
        )
    }
}
