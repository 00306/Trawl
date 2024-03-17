//
//  File.swift
//
//
//  Created by Eric on 2/6/24.
//

import Foundation
import SwiftUI


// Boids 시뮬레이션 클래스
class Boids: ObservableObject {
    @Published var boids: [Boid] = []
    let bounds: CGRect
    let padding: CGFloat
    let separationDistance: CGFloat
    let separationFactor: CGFloat
    let alignmentDistance: CGFloat
    let alignmentFactor: CGFloat
    let cohesionDistance: CGFloat
    let cohesionFactor: CGFloat
    let maxSpeed: CGFloat

    init(bounds: CGRect, boidCount: Int, padding: CGFloat,
         separationDistance: CGFloat, separationFactor: CGFloat,
         alignmentDistance: CGFloat, alignmentFactor: CGFloat,
         cohesionDistance: CGFloat, cohesionFactor: CGFloat,
         maxSpeed: CGFloat) {
        self.bounds = bounds
        self.padding = padding
        self.separationDistance = separationDistance
        self.separationFactor = separationFactor
        self.alignmentDistance = alignmentDistance
        self.alignmentFactor = alignmentFactor
        self.cohesionDistance = cohesionDistance
        self.cohesionFactor = cohesionFactor
        self.maxSpeed = maxSpeed

        initializeBoids(count: boidCount)
        
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            self.update()
        }
    }

    func initializeBoids(count: Int) {
        for _ in 0..<count {
            let position = CGPoint(x: CGFloat.random(in: bounds.minX...bounds.maxX),
                                   y: CGFloat.random(in: bounds.minY...bounds.maxY))
            let velocity = CGVector(dx: CGFloat.random(in: -1...1), dy: CGFloat.random(in: -1...1))
            boids.append(Boid(position: position, velocity: velocity))
        }
    }

    func update() {
        for i in 0..<boids.count {
            boids[i].applySeparation(boids: boids, separationDistance: separationDistance, separationFactor: separationFactor)
            boids[i].applyAlignment(boids: boids, alignmentDistance: alignmentDistance, alignmentFactor: alignmentFactor)
            boids[i].applyCohesion(boids: boids, cohesionDistance: cohesionDistance, cohesionFactor: cohesionFactor)

            boids[i].applyBounds(bounds: bounds, padding: padding)

            boids[i].limitVelocity(maxSpeed: maxSpeed)

            boids[i].position.x += boids[i].velocity.dx
            boids[i].position.y += boids[i].velocity.dy

        }
    }
}
