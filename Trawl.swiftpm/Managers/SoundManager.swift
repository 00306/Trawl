//
//  File.swift
//
//
//  Created by 송지혁 on 2/7/24.
//

import AVKit
import Foundation


class SoundManager: ObservableObject {
    @Published var player = AVPlayer()
    
    enum Sounds: String {
        case wave = "wave"
        case attention = "attention"
        case piano = "piano"
        case scissor = "scissor"
    }
    
    func playSound(sound: Sounds, volume: Float, repeatForever: Bool) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else { return }
        player = AVPlayer(url: url)
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        controlVolumeSmoothly(to: volume, duration: 0.1) { }
        
        
            NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: playerItem, queue: .main) { _ in
                if repeatForever {
                    self.player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                    self.player.play()
                }
            }
        
        player.play()
    }
    
    func stopSound() {
        player.replaceCurrentItem(with: nil)
    }
    
    func controlVolumeSmoothly(to targetVolume: Float, duration: TimeInterval, completion: @escaping () -> ()) {
        let interval: TimeInterval = 0.1 // 시간 간격 (초)
        let steps = Int(duration / interval) // 전체 단계 수
        let volumeStep = (targetVolume - player.volume) / Float(steps) // 각 단계별 볼륨 변화량
        
        var stepCount = 0
        
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if stepCount < steps {
                self.player.volume += volumeStep
                stepCount += 1
            } else {
                timer.invalidate()
                completion()
            }
        }
        timer.fire()
    }
}
