//
//  SwiftUIView.swift
//
//
//  Created by Eric on 2/13/24.
//

import SwiftUI

struct FishingNet: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var shakingEffectDegree: CGFloat = 1.5
    
    var body: some View {
        Image("fishingNet")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay {
                LinearGradient(colors: [.deepSea, .black.opacity(0.6)], startPoint: UnitPoint(x: 0.3, y: 0.3), endPoint: UnitPoint(x: 1, y: 1))
                    .mask {
                        Image("fishingNetSilhouette")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(1.01)
                    }
            }
            .scaleEffect(2.5)
            .rotationEffect(Angle(degrees: -45), anchor: .topLeading)
            .rotation3DEffect(Angle(degrees: shakingEffectDegree), axis: (x: 0, y: 1, z: 0))
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    self.shakingEffectDegree = -1.5
                }
            }
    }
}
