//
//  SwiftUIView.swift
//
//
//  Created by Eric on 2/4/24.
//

import SwiftUI

struct SinWave: Shape {
    var amplitude: Double
    var frequency: Double
    var phase: Double
    var degree: Double
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = Double(rect.width)
        let height = Double(rect.height)
        let midWidth = width / 2
        let midHeight = height / 2
        let oneOverMidWidth = 1 / midWidth
        
        let wavelength = width / frequency
        path.move(to: CGPoint(x: -midWidth, y: midHeight))
        
        for x in stride(from: -midWidth, through: width, by: 3) {
            let relativeX = x / wavelength
            let distanceFromMidWidth = width - x
            let normalDistance = oneOverMidWidth * distanceFromMidWidth
            let parabola = normalDistance
            
            let sine = sin(relativeX + phase)
            let y = parabola * amplitude * sine + midHeight
            path.addLine(to: CGPoint(x: x, y: y))
            
        }
        
        var rotatedPath = Path()
        
        rotatedPath.move(to: CGPoint(x: width, y: midHeight))
        for x in stride(from: width, through: -midWidth, by: -3) {
            let relativeX = x / wavelength
            let distanceFromMidWidth = x - width
            let normalDistance = oneOverMidWidth * distanceFromMidWidth
            let parabola = normalDistance
            
            let sine = sin(relativeX + phase)
            let y = parabola * amplitude * sine + midHeight
            rotatedPath.addLine(to: CGPoint(x: x, y: y))
            
        }
        let rotatedWave = rotatedPath.rotation(Angle(degrees: degree), anchor: .trailing).path(in: rect)
        
        path.addPath(rotatedWave)
        
        path.addCurve(to: CGPoint(x: -midWidth, y: midHeight),
                      control1: CGPoint(x: -rect.midX, y: -rect.midY),
                      control2: CGPoint(x: -rect.midX, y: rect.midY))
        
        
        

        
        
        return path
    }
}
