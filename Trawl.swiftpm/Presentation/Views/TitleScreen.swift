//
//  SwiftUIView.swift
//
//
//  Created by Eric on 2/15/24.
//

import SwiftUI

struct TitleScreen: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var soundManager: SoundManager
    @State private var animationStart = false
    @State private var tapDisabled = false
    
    
    var body: some View {
        ZStack {
            seaSurface
            Group {
                Waves(animationStart: $animationStart)
                    
                    .overlay(alignment: .trailing) {
                        Boat()
                    }
                    .rotationEffect(Angle(degrees: 20))
                
            }
            .offset(x: animationStart ? 150 : -150, y: animationStart ? 200 : 0)
            
            VStack() {
                Spacer()
                startButton
            }
            .padding(50)
        }
        .ignoresSafeArea()
        .onTapGesture {
            tapDisabled = true
            soundManager.controlVolumeSmoothly(to: 0, duration: 1) {
                soundManager.playSound(sound: .piano, volume: 0.2, repeatForever: true)
                withAnimation(.easeInOut(duration: 5)) {
                    animationStart = true
                }
                withAnimation(.linear(duration: 1).delay(6)) {
                    gameManager.startGame = true
                }
                }
        }
        .disabled(tapDisabled)
        
    }
    
    private var seaSurface: some View {
        Rectangle()
            .fill(Color.sea)
    }
    
    private var startButton: some View {
            Text("TAP ANYWHERE TO START")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.8), radius: 20)
                .opacity(gameManager.startGame ? 0 : 1)
                .animation(.easeInOut(duration: 2), value: gameManager.startGame)
    }
}
