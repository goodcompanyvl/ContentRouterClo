import SwiftUI

struct LightningProgressBar: View {
    let progress: Double
    let color: Color
    
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 3)
                
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.3),
                                    color,
                                    color
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(geometry.size.width) * CGFloat(progress), height: 3)
                    
                    if progress > 0 && progress < 0.999 {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .shadow(color: color.opacity(0.8), radius: 4)
                            .scaleEffect(CGFloat(1.0 + (sin(animationProgress * CGFloat.pi * 2) * 0.3)))
                    }
                }
                
                if progress > 0 && progress < 0.999 {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 30, height: 3)
                        .offset(x: CGFloat(geometry.size.width) * CGFloat(progress) - 15)
                        .opacity(Double((sin(animationProgress * CGFloat.pi * 2) * 0.5) + 0.5))
                }
            }
        }
        .frame(height: 3)
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                animationProgress = 1
            }
        }
    }
}

#Preview("Lightning Progress Bar") {
    VStack(spacing: 40) {
        Text("Lightning Progress Bar Demo")
            .font(.headline)
            .padding(.top, 40)
        
        VStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Blue - 30%")
                    .font(.caption)
                    .foregroundColor(.gray)
                LightningProgressBar(progress: 0.3, color: .blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Green - 50%")
                    .font(.caption)
                    .foregroundColor(.gray)
                LightningProgressBar(progress: 0.5, color: .green)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Orange - 70%")
                    .font(.caption)
                    .foregroundColor(.gray)
                LightningProgressBar(progress: 0.7, color: .orange)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Red - 90%")
                    .font(.caption)
                    .foregroundColor(.gray)
                LightningProgressBar(progress: 0.9, color: .red)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Purple - 100%")
                    .font(.caption)
                    .foregroundColor(.gray)
                LightningProgressBar(progress: 1.0, color: .purple)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Animated Progress")
                    .font(.caption)
                    .foregroundColor(.gray)
                AnimatedProgressDemo()
            }
        }
        .padding(.horizontal, 20)
        
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(UIColor.systemBackground))
}

struct AnimatedProgressDemo: View {
    @State private var progress: Double = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 16) {
            LightningProgressBar(progress: progress, color: .cyan)
            
            HStack {
                Button("Reset") {
                    timer?.invalidate()
                    timer = nil
                    progress = 0
                }
                .buttonStyle(.bordered)
                
                Button("Animate") {
                    timer?.invalidate()
                    progress = 0
                    
                    timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { t in
                        progress += 0.016 / 3.0
                        
                        if progress >= 1.0 {
                            progress = 1.0
                            t.invalidate()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            Text("Progress: \(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}

