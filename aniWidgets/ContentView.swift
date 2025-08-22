import SwiftUI

struct ContentView: View {
    @StateObject private var designManager = DesignManager.shared
    @State private var selectedCategory: String? = nil
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Header
                    heroHeaderView
                    
                    // Featured Designs Section
                    featuredSelectorView
                    
                    // Design Categories
                    designCategoriesView
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("aniWidgets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .onAppear {
            designManager.loadAvailableDesigns()
        }
    }
    
    private var heroHeaderView: some View {
        VStack(spacing: 16) {
            Text("Animate Your iPhone")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Create beautiful animated widgets with our collection of stunning designs")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "apps.iphone")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("Easy Setup")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                VStack {
                    Image(systemName: "paintbrush.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                    Text("Beautiful")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                VStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Animated")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .padding(.top, 10)
        }
        .padding(.vertical, 20)
    }
    
    private var featuredSelectorView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Featured Designs")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Sync Button
                if designManager.hasPendingChanges {
                    Button(action: {
                        Task {
                            await designManager.syncFeaturedDesigns()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if designManager.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.footnote)
                            }
                            Text("Sync")
                                .font(.footnote)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(designManager.isSyncing)
                    .animation(.easeInOut(duration: 0.2), value: designManager.isSyncing)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
            
            // Featured Slots Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(0..<4, id: \.self) { index in
                    FeaturedSlotView(
                        slotIndex: index,
                        design: designManager.getFeaturedDesign(for: index)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private var designCategoriesView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section Header
            HStack {
                Text("Widget Designs")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(designManager.availableDesigns.count) Available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // Categories
            let categories = Dictionary(grouping: designManager.availableDesigns) { $0.category }
            
            ForEach(categories.keys.sorted(), id: \.self) { category in
                CategorySectionView(
                    category: category,
                    designs: categories[category] ?? [],
                    isExpanded: selectedCategory == category
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

struct FeaturedSlotView: View {
    let slotIndex: Int
    let design: DesignModel?
    @ObservedObject private var designManager = DesignManager.shared
    
    private var slotLetter: String {
        ["A", "B", "C", "D"][slotIndex]
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(design == nil ? Color(.systemGray6) : Color.clear)
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 2)
                            .opacity(design == nil ? 1 : 0)
                    )
                
                if let design = design {
                    if design.id == "test01" {
                        // Bundle image için doğrudan Image kullan
                        Image("frame_01")
                            .resizable()
                            .aspectRatio(1.0, contentMode: .fill)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        AsyncImage(url: design.previewImageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(1.0, contentMode: .fill)
                                .clipped()
                                .cornerRadius(12)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .aspectRatio(1.0, contentMode: .fit)
                                .overlay(
                                    ProgressView()
                                )
                        }
                    }
                } else {
                    VStack {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Slot \(slotLetter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onTapGesture {
                if design != nil {
                    designManager.removeFromFeatured(at: slotIndex)
                }
            }
            .contextMenu {
                if design != nil {
                    Button("Remove", role: .destructive) {
                        designManager.removeFromFeatured(at: slotIndex)
                    }
                }
            }
        }
    }
}

struct CategorySectionView: View {
    let category: String
    let designs: [DesignModel]
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggle) {
                HStack {
                    Text(category.capitalized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(designs.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(designs, id: \.id) { design in
                        DesignCardView(design: design)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct DesignCardView: View {
    let design: DesignModel
    @ObservedObject private var designManager = DesignManager.shared
    
    private var isInFeatured: Bool {
        designManager.featuredDesigns.contains { $0.id == design.id }
    }
    
    private var canAddToFeatured: Bool {
        designManager.featuredDesigns.count < 4
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if design.id == "test01" {
                    // Bundle image için doğrudan Image kullan
                    Image("frame_01")
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fill)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    AsyncImage(url: design.previewImageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(1.0, contentMode: .fill)
                            .clipped()
                            .cornerRadius(12)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(
                                ProgressView()
                            )
                    }
                }
                
                // Featured Badge
                if isInFeatured {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(6)
                        }
                        Spacer()
                    }
                    .padding(6)
                }
            }
            
            Text(design.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
        .onTapGesture {
            if isInFeatured {
                if let index = designManager.featuredDesigns.firstIndex(where: { $0.id == design.id }) {
                    designManager.removeFromFeatured(at: index)
                }
            } else if canAddToFeatured {
                Task {
                    await designManager.addToFeatured(design)
                }
            }
        }
        .contextMenu {
            if isInFeatured {
                Button("Remove from Featured", role: .destructive) {
                    if let index = designManager.featuredDesigns.firstIndex(where: { $0.id == design.id }) {
                        designManager.removeFromFeatured(at: index)
                    }
                }
            } else if canAddToFeatured {
                Button("Add to Featured") {
                    Task {
                        await designManager.addToFeatured(design)
                    }
                }
            }
        }
        .opacity(canAddToFeatured || isInFeatured ? 1.0 : 0.6)
    }
}

#Preview {
    ContentView()
}
