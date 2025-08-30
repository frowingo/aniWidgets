import SwiftUI
import SharedKit

struct AllDesignsView: View {
    @ObservedObject private var designManager = DesignManager.shared
    @State private var searchText = ""
    
    var filteredDesigns: [AnimationDesign] {
        if searchText.isEmpty {
            return designManager.availableDesigns
        } else {
            return designManager.availableDesigns.filter { design in
                design.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBarView
            
            // Designs Grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
                    ForEach(filteredDesigns, id: \.id) { design in
                        PrevislyDesignCard(design: design)
                    }
                }
                .padding(20)
            }
        }
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search designs...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct PrevislyDesignCard: View {
    let design: AnimationDesign
    @ObservedObject private var designManager = DesignManager.shared
    
    private var isInFeatured: Bool {
        designManager.featuredConfig.designs.contains(design.id)
    }
    
    private var isDownloaded: Bool {
        designManager.isDesignDownloaded(design.id)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Design Preview
            ZStack {
                // Use design's preview image
                if design.id == "test01" {
                    // Bundle image için doğrudan Image kullan
                    Image("test01_frame_01")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    // Diğer tasarımlar için placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                Text(design.name)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                }
                
                // Featured Badge
                if isInFeatured {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.7))
                                        .frame(width: 24, height: 24)
                                )
                        }
                        Spacer()
                    }
                    .frame(width: 140, height: 140)
                    .padding(8)
                }
            }
            
            // Design Info
            VStack(spacing: 4) {
                Text(design.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("\(design.frameCount) frames")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            // Action Button
            actionButton
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isInFeatured ? Color.blue : Color(.systemGray4), lineWidth: isInFeatured ? 2 : 1)
        )
        .cornerRadius(20)
    }
    
    @ViewBuilder
    private var actionButton: some View {
        if isInFeatured {
            // Remove from Featured
            Button(action: {
                withAnimation {
                    designManager.removeFromFeatured(design.id)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "star.slash.fill")
                    Text("Remove")
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
        } else if designManager.featuredConfig.designs.count >= 4 {
            // Featured is full
            Button(action: {}) {
                Text("Featured Full")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            .disabled(true)
            
        } else {
            // Add to Featured
            Button(action: {
                withAnimation {
                    designManager.addToFeatured(design.id)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                    Text("Add to Featured")
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    NavigationView {
        AllDesignsView()
    }
}