//
//  SwiftUIView.swift
//
//
//  Created by Eric on 2/15/24.
//

import GameController
import SwiftUI
import SpriteKit

struct Map: View {
    @State private var fadeIn = false
    @State private var isTapped = false
    
    @State private var closeNotification = false
    @State private var clickedDashButton = false
    @State private var clickedSlashButton = false
    
    @State private var startTutorial = false
    @StateObject var scene = GameScene()
    @EnvironmentObject var gameManager: GameManager
    
    func co2Concentration() -> Color {
        switch scene.co2Concentration {
        case ..<20:
            return .white
        case 20..<60:
            return .orange
        default:
            return .red
            
        }
    }
    
    var body: some View {
        ZStack {
            Rectangle().fill(.black)
            if fadeIn {
                SpriteView(scene: scene)
                    .onDisappear {
                        scene.restartGame()
                    }
            }
            Color.orange.opacity(0.1)
                .opacity(scene.co2Concentration > 10 ? 1 : 0)
                .animation(.easeInOut(duration: 10), value: scene.co2Concentration)
            
            Color.red.opacity(0.2)
                .opacity(scene.co2Concentration > 30 ? 1 : 0)
                .animation(.easeInOut(duration: 10), value: scene.co2Concentration)
            Color.red.opacity(0.2)
                .opacity(scene.co2Concentration > 60 ? 1 : 0)
                .animation(.easeInOut(duration: 10), value: scene.co2Concentration)
            
            if let _ = GCController.controllers().first?.extendedGamepad {
                VStack {
                    HStack {
                        if scene.life >= 1 {
                            ForEach(0..<Int(scene.life), id: \.self) { _ in
                                Image("heart")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100)
                                    .padding(.top)
                            }
                        }
                        
                        Spacer()
                        VStack(spacing: 0) {
                            Text(String(format: "%.2f", scene.co2Concentration))
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                                .foregroundStyle(co2Concentration())
                            
                            Image("CO2")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20)
                        }
                            .padding(.trailing)
                    }
                    .padding([.leading, .top], 20)
                    .monospacedDigit()
                    
                    Spacer()
                    HStack(alignment: .bottom) {
                        Spacer()
                        dashButton
                        VStack {
                            slashButton
                            Circle()
                                .fill(.clear)
                                .frame(width: 110, height: 110)
                        }
                        
                    }
                    .padding(50)
                }
                
            }
                
            
            if startTutorial, scene.tutorialState == .dash {
                TutorialNotification(state: .dash)
                    .transition(.opacity)
                    .onTapGesture {
                        nextTutorial()
                    }
            } else if scene.tutorialState == .slash {
                TutorialNotification(state: .slash)
                    .transition(.opacity)
                    .onTapGesture {
                        nextTutorial()
                    }
            } else if scene.tutorialState == .corals {
                TutorialNotification(state: .corals)
                    .transition(.opacity)
                    .onTapGesture {
                        nextTutorial()
                    }
            }
            
            if scene.isGameOver {
                Color.black
                    .opacity(0.8)
                VStack {
                    Text(scene.cause)
                        .font(.system(size: 40, weight: .regular))
                        .padding(.bottom, 40)
                    Text("Game Over")
                    
                    Text("Survival time: \(scene.playtime)")
                    Text("Cropped fishing nets: \(scene.cutNet)")
                    
                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 2)) {
                                gameManager.startGame = false
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                                    scene.view?.presentScene(GameScene())
//                                }
                            }
                        } label: {
                            Text("End")
                        }
                    }
                }
            }
            
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 1).delay(8)) {
                fadeIn = true
            }
        }
        .onChange(of: scene.tutorialState, perform: { _ in
            if scene.tutorialState == .dash {
                withAnimation(.easeInOut(duration: 1)) {
                    startTutorial = true
                }
            }
        })
    }
    
    
    private var dashButton: some View {
        Button {
            scene.dash()
            clickedDashButton = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                clickedDashButton = false
            }
        } label: {
            Circle()
                .fill(.bar)
                .overlay {
                    Image("dashButton_2")
                        .resizable()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                }
                .frame(width: 110, height: 110)
        }
        .disabled(clickedDashButton)
    }
    
    private var slashButton: some View {
        Button {
            scene.slash()
            clickedSlashButton = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                clickedSlashButton = false
            }
        } label: {
            Circle()
                .fill(.bar)
                .overlay {
                    Image("slashButton_2")
                        .resizable()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                }
                .frame(width: 110, height: 110)
        }
        .disabled(clickedSlashButton)
    }
    
    private func nextTutorial() {
        withAnimation(.easeInOut(duration: 1)) {
            switch scene.tutorialState {
            case .dash:
                scene.tutorialState = .slash
                    
            case .slash:
                scene.tutorialState = .corals
            default:
                scene.tutorialState = nil
                scene.isPaused = false
                scene.marlinNode.physicsBody?.collisionBitMask  = PhysicsCategory.TrawlingNet | PhysicsCategory.Line
                scene.startTime = Date().timeIntervalSince1970
                scene.tutorialComplete = true
                }
        }
    }
}
