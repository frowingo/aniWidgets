import SwiftUI
import SharedKit

struct ContentView: View {
    @StateObject private var designManager = DesignManager.shared
    
    var body: some View {
        
        FeaturedDesignsView()
            .preferredColorScheme(.light) // Force light mode
        
    }
    
    private func loadFeaturedDesigns() {
        designManager.loadFeaturedConfig()
    }
}

#Preview {
    ContentView()
}
