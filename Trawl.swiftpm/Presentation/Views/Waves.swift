//
//  SwiftUIView.swift
//
//
//  Created by Eric on 2/6/24.
//

import SwiftUI

struct Waves: View {
    @State private var phase = 0.0
    @Binding var animationStart: Bool
    
    @StateObject var soundManager: SoundManager = SoundManager()
    
    var waveAnimation: Animation {
        Animation
            .linear(duration: 2)
            .repeatForever(autoreverses: false)
    }
    
    var body: some View {
        ZStack {
            shallowSea

            ZStack {
                FishFlock()
                    .opacity(animationStart ? -0.8 : 0.8)
                FishingNet()
                    .animation(.easeIn(duration: 6).delay(2), value: animationStart)
                    .offset(x: animationStart ? 750 : -1500, y: animationStart ? 450 : -450)
            }
            .mask {
                SinWave(amplitude: 15, frequency: 30, phase: phase, degree: 45)
                    .fill(Color.deepSea.shadow(.inner(color: .black, radius: 20, x: 0, y: 0)))
                    .scaleEffect(0.96, anchor: .topLeading)
                    .animation(waveAnimation.speed(1.3), value: phase)
                    .rotationEffect(Angle(degrees: 5), anchor: .bottomTrailing)
            }
            .background {
                SinWave(amplitude: 15, frequency: 30, phase: phase, degree: 45)
                    .fill(Color.deepSea.shadow(.inner(color: .black, radius: 5, x: 40, y: 0)))
                    .scaleEffect(0.96, anchor: .topLeading)
                    .animation(waveAnimation.speed(1.3), value: phase)
                    .rotationEffect(Angle(degrees: 5), anchor: .bottomTrailing)
            }
        }
        .padding(.trailing, 30)
        .onAppear {
            soundManager.playSound(sound: .wave, volume: 0.1, repeatForever: true)
            withAnimation(waveAnimation) {
                self.phase = .pi * 2
            }
        }
        .onDisappear {
            soundManager.stopSound()
        }
    }
    
    var shallowSea: some View {
        SinWave(amplitude: 20, frequency: 27, phase: phase, degree: 60)
            .fill(Color.shallowSea.shadow(.inner(color: .black, radius: 5, x: 40, y: -5)))
    }
}
