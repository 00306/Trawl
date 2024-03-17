//
//  SwiftUIView.swift
//
//
//  Created by Eric on 2/6/24.
//

import SwiftUI

struct Boat: View {
    @State private var shipAnimate = false
    
    var body: some View {
        HStack {
            Image("trawler")
                .resizable()
                .scaledToFit()
                .frame(width: 150)
                .rotation3DEffect(Angle(degrees: shipAnimate ? 6 : -6), axis: (x: 1, y: 1, z: 0))
                .offset(x: shipAnimate ? 10 : 0, y: shipAnimate ? 10 : 0)
                .rotationEffect(Angle(degrees: -25), anchor: .topLeading)
        }
        
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                shipAnimate = true
            }
        }
    }
}
