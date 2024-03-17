//
//  SwiftUIView.swift
//
//
//  Created by Eric on 2/6/24.
//

import SwiftUI

struct FishSilhouetteShape: Shape {
        var direction: Double
        
        var animatableData: Double {
            get { direction }
            set { direction = newValue }
        }
    
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let midWidth = width / 2
        let height = rect.height
        let midHeight = height / 2
        
        var path = Path()
        path.move(to: CGPoint(x: midWidth, y: height * 0.2))
        path.addCurve(to: CGPoint(x: midWidth + direction * 0.4, y: rect.maxY),
                      control1: CGPoint(x: width * 1.1, y: height * 0.288),
                      control2: CGPoint(x: width * 0.77 + direction, y: midHeight * 1.2))
        
        path.addCurve(to: CGPoint(x: midWidth, y: height * 0.2),
                      control1: CGPoint(x: width * 0.35 + direction, y: height * 0.7),
                      control2: CGPoint(x: -width * 0.2, y: height * 0.22 + direction))
        
        return path
    }
}
