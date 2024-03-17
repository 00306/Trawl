//
//  SwiftUIView.swift
//
//
//  Created by Eric on 2/7/24.
//

import SwiftUI

struct FishFlock: View {
    @State private var direction: Double = -5.0
    @StateObject var boids = Boids(bounds: CGRect(x: 0, y: 0, width: 1000, height: 1000), boidCount: 60, padding: -10, separationDistance: 30, separationFactor: 0.6, alignmentDistance: 50, alignmentFactor: 1, cohesionDistance: 40, cohesionFactor: 0.1, maxSpeed: 3.0)
    
    var fishAnimation: Animation {
        Animation
            .easeInOut(duration: 0.4)
            .repeatForever(autoreverses: true)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(zip(boids.boids.indices, boids.boids)), id: \.0) { index, boid in
                    FishSilhouetteShape(direction: 5)
                        .fill(Color.black.opacity(0.5))
                        .scaleEffect(Double(index * 2) / Double(boids.boids.count - 1) * 0.4 + 1.2)
                        .frame(width: 12, height: 32)
                        .position(boid.position)
                        .rotationEffect(Angle(degrees: 90))

                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                withAnimation(fishAnimation) {
                    self.direction = 5
                }
            }
        }
    }
}
