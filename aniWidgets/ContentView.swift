import SwiftUI

struct ContentView: View {
    @AppStorage("currentFrameIndex", store: UserDefaults(suiteName: "group.Iworf.aniWidgets")) 
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
            
            // Frame preview
            framePreview
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            Button(action: {
                playAnimation()
            }) {
                Text("Play Animation")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
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
        
        return VStack(spacing: 20) {
            Text("Current Frame: \(currentFrame)")
                .font(.headline)
            
            // Debug için UIImage ile test edelim
            if let image = UIImage(named: frameName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .border(Color.gray, width: 1)
            } else {
                // Görsel bulunamazsa
                Rectangle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .overlay(
                        VStack {
                            Text("Image Not Found")
                                .foregroundColor(.red)
                            Text(frameName)
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                    )
                    .border(Color.red, width: 2)
            }
            
            Text("Looking for: \(frameName)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    func playAnimation() {
        isAnimating = true
        currentFrame = 1
        
        animateWithDynamicTiming()
    }
    
        private func animateWithDynamicTiming() {
        let totalFrames = 24
        @State var currentIndex = 0
        let minDelay = 0.7  // Minimum süre (0.7 saniye)
        let maxDelay = 1.5  // Maksimum süre (1.5 saniye)
        
        func getDelayForFrame(_ frameIndex: Int) -> TimeInterval {
            let normalizedPosition = Double(frameIndex) / Double(totalFrames - 1) // 0.0 - 1.0 arası
            
            // Logaritmik eğri oluştur (0'dan 0.5'e kadar artış, 0.5'den 1'e kadar azalış)
            let distanceFromCenter = abs(normalizedPosition - 0.5) * 2.0 // 0.0 - 1.0 arası
            
            // Logaritmik hesaplama (merkezde yavaş, kenarlarda hızlı)
            let logFactor = 1.0 - log(1.0 + distanceFromCenter * (exp(1.0) - 1.0)) / 1.0
            
            return minDelay + (maxDelay - minDelay) * logFactor
        }
        
        func animateNextFrame() {
            guard currentIndex < totalFrames else {
                // Animasyon bitti, başa dön
                currentFrame = 1
                isAnimating = false
                return
            }
            
            currentFrame = currentIndex + 1
            currentIndex += 1
            
            let delay = getDelayForFrame(currentIndex - 1)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                animateNextFrame()
            }
        }
        
        currentIndex = 0
        isAnimating = true
        animateNextFrame()
    }
}

#Preview {
    ContentView()
}
