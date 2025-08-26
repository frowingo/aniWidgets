import SwiftUI
import WidgetKit
import SharedKit

struct FeaturedDesignsView: View {
    @ObservedObject private var designManager = DesignManager.shared
    @State private var draggedDesign: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status Info
                statusInfoView
                
                // Featured Slots (4 slots)
                featuredSlotsView
                
                // Add More Button
                if designManager.featuredConfig.designs.count < 4 {
                    addMoreButton
                }
                
                // Widget Gallery Preview
                widgetGalleryPreview
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var statusInfoView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
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
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
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
    
    private var addMoreButton: some View {
        NavigationLink(destination: DesignSelectionView()) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add More Designs")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
    }
    
    private var widgetGalleryPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "rectangle.3.group")
                Text("Widget Gallery Preview")
                    .font(.headline)
                Spacer()
            }
            
            Text("This is how your widgets will appear when adding to home screen:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(0..<4, id: \.self) { slotIndex in
                    WidgetGalleryPreview(
                        slotIndex: slotIndex,
                        design: slotIndex < designManager.featuredConfig.designs.count ? 
                               designManager.getDesign(by: designManager.featuredConfig.designs[slotIndex]) : nil
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
        VStack(spacing: 12) {
            // Slot Header
            HStack {
                Text(slotLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                
                if design != nil {
                    Button(action: {
                        if let designId = design?.id {
                            onRemove(designId)
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 18))
                    }
                }
            }
            
            // Design Preview
            if let design = design {
                VStack(spacing: 8) {
                    // Frame preview (using bundle assets for now)
                    Image("frame_01")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Text(design.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                    Text("\(design.frameCount) frames")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            } else {
                // Empty slot
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        )
                    
                    Text("Empty Slot")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(design != nil ? Color.blue : Color(.systemGray4), lineWidth: design != nil ? 2 : 1)
        )
        .cornerRadius(16)
    }
}

struct WidgetGalleryPreview: View {
    let slotIndex: Int
    let design: AnimationDesign?
    
    private var widgetName: String {
        if let design = design {
            return design.name
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
