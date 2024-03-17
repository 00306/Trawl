//
//  SwiftUIView.swift
//
//
//  Created by Eric on 2/7/24.
//

import Foundation

struct Boid: Identifiable {
    var id: String = UUID().uuidString
    
    var position: CGPoint
    var velocity: CGVector
    
    // 분리 규칙 적용
    mutating func applySeparation(boids: [Boid], separationDistance: CGFloat, separationFactor: CGFloat) {
        var separationVector = CGVector.zero
        var separationCount = 0
        
        for otherBoid in boids {
            let distance = sqrt(pow(position.x - otherBoid.position.x, 2) + pow(position.y - otherBoid.position.y, 2))
            if distance > 0 && distance < separationDistance {
                let diffX = position.x - otherBoid.position.x
                let diffY = position.y - otherBoid.position.y
                separationVector.dx += diffX / distance
                separationVector.dy += diffY / distance
                separationCount += 1
            }
        }
        
        if separationCount > 0 {
            separationVector.dx /= CGFloat(separationCount)
            separationVector.dy /= CGFloat(separationCount)
            separationVector.dx *= separationFactor
            separationVector.dy *= separationFactor
            velocity.dx += separationVector.dx
            velocity.dy += separationVector.dy
        }
    }

    // 이동 규칙 적용
    mutating func applyAlignment(boids: [Boid], alignmentDistance: CGFloat, alignmentFactor: CGFloat) {
        var averageVelocity = CGVector.zero
        var alignmentCount = 0
        
        for otherBoid in boids {
            let distance = sqrt(pow(position.x - otherBoid.position.x, 2) + pow(position.y - otherBoid.position.y, 2))
            if distance > 0 && distance < alignmentDistance {
                averageVelocity.dx += otherBoid.velocity.dx
                averageVelocity.dy += otherBoid.velocity.dy
                alignmentCount += 1
            }
        }
        
        if alignmentCount > 0 {
            averageVelocity.dx /= CGFloat(alignmentCount)
            averageVelocity.dy /= CGFloat(alignmentCount)
            averageVelocity.dx *= alignmentFactor
            averageVelocity.dy *= alignmentFactor
            velocity.dx += averageVelocity.dx
            velocity.dy += averageVelocity.dy
        }
    }

    // 결집 규칙 적용
    mutating func applyCohesion(boids: [Boid], cohesionDistance: CGFloat, cohesionFactor: CGFloat) {
        var centerOfMass = CGPoint.zero
        var cohesionCount = 0
        
        for otherBoid in boids {
            let distance = sqrt(pow(position.x - otherBoid.position.x, 2) + pow(position.y - otherBoid.position.y, 2))
            if distance > 0 && distance < cohesionDistance {
                centerOfMass.x += otherBoid.position.x
                centerOfMass.y += otherBoid.position.y
                cohesionCount += 1
            }
        }
        
        if cohesionCount > 0 {
            centerOfMass.x /= CGFloat(cohesionCount)
            centerOfMass.y /= CGFloat(cohesionCount)
            let deltaX = centerOfMass.x - position.x
            let deltaY = centerOfMass.y - position.y
            let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
            let directionX = (distance > 0) ? deltaX / distance : 0
            let directionY = (distance > 0) ? deltaY / distance : 0
            velocity.dx += directionX * cohesionFactor
            velocity.dy += directionY * cohesionFactor
        }
    }

    // 경계 처리
    mutating func applyBounds(bounds: CGRect, padding: CGFloat) {
        if position.x < bounds.minX + padding {
            velocity.dx += 2
        }
        if position.x > bounds.maxX - padding {
            velocity.dx -= 2
        }
        if position.y < bounds.minY + padding {
            velocity.dy += 2
        }
        if position.y > bounds.maxY - padding {
            velocity.dy -= 2
        }
    }

    // 속도 제한
    mutating func limitVelocity(maxSpeed: CGFloat) {
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        if speed > maxSpeed {
            let factor = maxSpeed / speed
            velocity.dx *= factor
            velocity.dy *= factor
        }
    }
}
