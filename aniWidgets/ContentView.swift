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

struct HeaderView: View {
    var body: some View {
        VStack {
            Text("🎨 Widget Gallery")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Beautiful animated widgets for your home screen")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct FeaturedDesignsSection: View {
    @EnvironmentObject var designManager: DesignManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Designs")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(designManager.featuredDesigns, id: \.name) { design in
                        FeaturedDesignCard(design: design)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct FeaturedDesignCard: View {
    let design: AnimationDesign
    
    var body: some View {
        VStack(spacing: 8) {
            // Preview Image
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.gradient)
                .frame(width: 120, height: 120)
                .overlay(
                    Text("🎨")
                        .font(.largeTitle)
                )
            
            // Design Name
            Text(design.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            // Frame Count
            Text("\(design.frameCount) frames")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 140)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct StatusInfoView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Widget Status")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                
                Text("Widgets Ready")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
