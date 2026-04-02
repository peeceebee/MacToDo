import SwiftUI

struct ScheduleiOSView: View {
    var body: some View {
        ContentUnavailableView(
            "Schedule",
            systemImage: "calendar.badge.clock",
            description: Text("Coming soon.")
        )
        .navigationTitle("Schedule")
    }
}
