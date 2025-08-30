import SwiftUI
import WidgetKit
import SharedKit

struct FeaturedDesignsView: View {
    @ObservedObject private var designManager = DesignManager.shared
    @State private var draggedDesign: String?
    @State private var showExpandableGrid: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                HeaderView()
                statusInfoView
                featuredSlotsView
                saveDesignButton
                expandableTestDesigns
                
                Spacer()
            }
            .padding()
        }
    }
    
    private struct HeaderView: View {
        var body: some View {
            VStack {
                Text("aniWidget App")
                    .font(.largeTitle.weight(.semibold))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.teal)
            .cornerRadius(12)
        }
    }
    
    private var statusInfoView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.teal)
                Text("\(designManager.featuredConfig.designs.count)/4 Featured Designs")
                    .font(.headline)
                Spacer()
            }
            
            if !designManager.featuredConfig.designs.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("These will appear in your widget gallery")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var featuredSlotsView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 4), spacing: 2) {
            ForEach(0..<4, id: \.self) { slotIndex in
                FeaturedSlotCard(
                    slotIndex: slotIndex,
                    design: slotIndex < designManager.featuredConfig.designs.count ?
                           designManager.getDesign(by: designManager.featuredConfig.designs[slotIndex]) : nil,
                    onRemove: { designId in
                        withAnimation {
                            designManager.removeFromFeatured(designId)
                        }
                    }
                )
            }
        }
    }
    
    private var expandableTestDesigns: some View {
        VStack(spacing: 0) {
            // Toggle Header
            Button(action: {
                withAnimation(.spring(response: 0.40, dampingFraction: 0.5, blendDuration: 0.5)) {
                    showExpandableGrid.toggle()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: showExpandableGrid ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(.teal)
                    Text("Test Collection")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            // Animated, collapsible grid body
            if showExpandableGrid {
                if designManager.testDesigns.isEmpty {
                    Text("No test designs found in bundle.\nCheck TestDesigns folder & filenames.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(designManager.testDesigns, id: \.id) { testDesign in
                        DesignPodiumSlotCard(
                            design: testDesign,
                            isInFeatured: designManager.featuredConfig.designs.contains(testDesign.id),
                            isFeaturedFull: designManager.featuredConfig.designs.count >= 4,
                            onAddToFeatured: { designId in
                                withAnimation {
                                    designManager.addToFeatured(designId)
                                }
                            },
                            onRemove: { _ in }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.top, 8)
                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity),
                                         removal: .move(edge: .top).combined(with: .opacity)))
                
                if designManager.testDesigns.count > 3 {
                    NavigationLink(destination: DesignSelectionView()) {
                        HStack(spacing: 8) {
                            Image(systemName: "eyes")
                            Text("See all designs for collection")
                            Image(systemName: "arrowshape.right.circle")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.mint)
                        .cornerRadius(12)
                    }
                    .padding(.top, 12)
                }
                
            }
        }
    }
    
    private var saveDesignButton: some View {
        NavigationLink(destination: DesignSelectionView()) {
            HStack {
                Image(systemName: "square.and.arrow.down.on.square")
                Text("Save Slots")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
    }
}

struct FeaturedSlotCard: View {
    let slotIndex: Int
    let design: AnimationDesign?
    let onRemove: (String) -> Void
    
    private var slotLabel: String {
        ["Slot A", "Slot B", "Slot C", "Slot D"][slotIndex]
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Slot Header
            HStack {
                
                if design != nil {
                    Button(action: {
                            if let designId = design?.id {
                                onRemove(designId)
                            }
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 1)
                            .background(Color.red)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                } else {
                    Text(slotLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            
            // Design Preview
            if let design = design {
                VStack(spacing: 10) {
                    // Frame preview (using bundle assets for now)
                    if let uiImg = DesignManager.shared.getFrameImage(for: design.id, frameIndex: 0) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 65, height: 65)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(width: 65, height: 65)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    Text(design.podiumName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                }
            } else {
                // Empty slot
                VStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(width: 65, height: 65)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        )
                }
            }
        }
        .frame(width: 50, height: 90)
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(design != nil ? Color.blue : Color(.systemGray4), lineWidth: design != nil ? 2 : 1)
        )
        .cornerRadius(16)
    }
}

struct DesignPodiumSlotCard: View {
    let design: AnimationDesign?
    let isInFeatured: Bool
    let isFeaturedFull: Bool
    let onAddToFeatured: (String) -> Void
    let onRemove: (String) -> Void
    
    private var isDisabled: Bool {
        guard design != nil else { return true }
        return isInFeatured || isFeaturedFull
    }
    
    var body: some View {
        Button(action: {
            guard let design = design, !isDisabled else { return }
            onAddToFeatured(design.id)
        }) {
            VStack(spacing: 8) {
                
                // Design Preview
                if let design = design {
                    VStack(spacing: 10) {
                        // Frame preview (using bundle assets for now)
                        if let uiImg = DesignManager.shared.getFrameImage(for: design.id, frameIndex: 0) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 85, height: 85)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                                .frame(width: 65, height: 65)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 18))
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        Text(design.podiumName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .foregroundColor(isDisabled ? .secondary : .primary)
                        
                        Text("\(design.frameCount) frames")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        // Status indicator
                        if isInFeatured {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Featured")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        } else if isFeaturedFull {
                            Text("Featured Full")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    // Empty slot
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(width: 65, height: 65)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray)
                            )
                        
                        Text("No Design")
                            .font(.caption)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                        
                        Text("Empty")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .disabled(isDisabled)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isInFeatured ? Color.yellow : 
                    (design != nil && !isDisabled ? Color.blue : Color(.systemGray4)), 
                    lineWidth: isInFeatured ? 2 : (design != nil ? 1 : 1)
                )
        )
        .cornerRadius(16)
        .opacity(isDisabled ? 0.6 : 1.0)
        .scaleEffect(isDisabled ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

struct WidgetGalleryPreview: View {
    let slotIndex: Int
    let design: AnimationDesign?
    
    private var widgetName: String {
        if let design = design {
            return design.podiumName
        } else {
            return "Slot \(["A", "B", "C", "D"][slotIndex])"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Widget Preview
            RoundedRectangle(cornerRadius: 8)
                .fill(design != nil ? Color.blue.opacity(0.1) : Color(.systemGray5))
                .frame(height: 60)
                .overlay(
                    Group {
                        if design != nil {
                            Image("frame_01")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            Image(systemName: "rectangle.dashed")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        }
                    }
                )
            
            Text(widgetName)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }
        .opacity(design != nil ? 1.0 : 0.5)
    }
}

#Preview {
    NavigationView {
        FeaturedDesignsView()
    }
}
