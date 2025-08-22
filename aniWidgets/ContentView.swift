import SwiftUI

struct ContentView: View {
    @AppStorage("currentFrame", store: UserDefaults(suiteName: "group.Iworf.aniWidgets")) 
    private var currentFrame: Int = 1
    
    @State private var isAnimating: Bool = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Animated Frame Widget")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Current Frame: \(currentFrame)")
                .font(.title)
                .foregroundColor(.blue)
            
            framePreview
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Button(action: {
                playAnimation()
            }) {
                Text(isAnimating ? "Animating..." : "Play Animation")
                    .font(.title2)
                    .padding()
                    .background(isAnimating ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isAnimating)
            
            Button(action: {
                currentFrame = 1
            }) {
                Text("Reset to Frame 1")
                    .font(.title2)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Text("Add widget to home screen and tap it to play animation!")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
    
    private var framePreview: some View {
        let frameName = "frame_\(String(format: "%02d", currentFrame))"
        
        return Image(frameName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 200, height: 200)
            .background(Color.gray.opacity(0.1))
    }
    
    func playAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        currentFrame = 1
        
        animateWithDynamicTiming()
    }
    
    private func animateWithDynamicTiming() {
        let totalFrames = 24
        let timings = [
            0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.4,
            1.3, 1.2, 1.1, 1.0, 0.9, 0.8, 0.7, 0.8, 0.9, 1.0,
            1.1, 1.2, 1.3, 1.4
        ]
        
        func animateFrame(_ index: Int) {
            guard index < totalFrames else {
                currentFrame = 1
                isAnimating = false
                return
            }
            
            currentFrame = index + 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + timings[index]) {
                animateFrame(index + 1)
            }
        }
        
        animateFrame(0)
    }
}

#Preview {
    ContentView()
}
