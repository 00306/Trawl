//
//  SwiftUIView.swift
//  
//
//  Created by 송지혁 on 2/25/24.
//

import SwiftUI

enum TutorialState: String {
    case dash = "Dash"
    case slash = "Slash"
    case corals = "Corals"
}

struct TutorialNotification: View {
    @State private var animate = false
    let soundManager = SoundManager()
    var state: TutorialState
    let dashTutorial = Tutorial(name: "Dash",
                                description: "Swim fast",
                                mainImage: "marlin_tutorial_normal",
                                animateImage: "marlin_tutorial_dash",
                                miniPad: "miniPad",
                                animateMiniPad: "miniPad_dash_click")
    
    let slashTutorial = Tutorial(name: "Slash",
                                 description: "cut the rope",
                                 mainImage: "tutorial_slash_main",
                                 animateImage: "tutorial_slash_animate",
                                 miniPad: "miniPad",
                                 animateMiniPad: "miniPad_slash_click")
    
    let coralsTutorial = Tutorial(name: "Corals",
                                  description: "Heal the wounds",
                                  mainImage: "tutorial_corals_main",
                                  animateImage: "tutorial_corals_animate",
                                  miniPad: "",
                                  animateMiniPad: "")
    var tutorial: Tutorial {
        switch state {
        case .dash:
            return dashTutorial
        case .slash:
            return slashTutorial
        case .corals:
            return coralsTutorial
        }
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
            
            RoundedRectangle(cornerRadius: 16)
                .fill(.bar)
                .frame(width: 450, height: 375)
                .overlay {
                    VStack {
                        Text(tutorial.name)
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .padding(.top)
                        Text(tutorial.description)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        
                       mainImage
                        
                        Spacer()
                        miniPad
                    }
                }
        }
        .onAppear {
            soundManager.playSound(sound: .attention, volume: 1, repeatForever: false)
            withAnimation(.easeInOut(duration: 1).repeatForever()) {
                animate.toggle()
            }
        }
    }
    
    private var mainImage: some View {
        Group {
            if animate {
                Image("\(tutorial.animateImage)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 400)
            } else {
                Image("\(tutorial.mainImage)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 400)
            }
        }
    }
    
    private var miniPad: some View {
        Group {
            if state != .corals {
                if animate {
                    Image("\(tutorial.animateMiniPad)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300)
                        .padding()
                } else {
                    Image("\(tutorial.miniPad)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300)
                        .padding()
                        .transition(.scale(scale: 0.999))
                }
            } else {
                EmptyView()
            }
        }
    }
}

struct Tutorial {
    let name: String
    let description: String
    let mainImage: String
    let animateImage: String
    let miniPad: String
    let animateMiniPad: String
}
