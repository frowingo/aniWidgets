import SwiftUI
import SharedKit

struct DesignSelectionView: View {
    @StateObject private var designManager = DesignManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 16) {
                    ForEach(designManager.availableDesigns, id: \.id) { design in
                        DesignCard(design: design) {
                            // Add to featured designs
                            designManager.addToFeatured(design.id)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Select Design")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DesignCard: View {
    let design: AnimationDesign
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Animation preview area
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 120)
                .overlay(
                    Text("Animation Preview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                )
            
            Text(design.name)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Button("Add to Featured") {
                onSelect()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    DesignSelectionView()
}
