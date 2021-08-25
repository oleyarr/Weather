//
//  ViewModel.swift
//  Weather
//
//  Created by Володя on 18.08.2021.
//

import Foundation
import AVKit

protocol ViewModel {
    var didSoundButtonPressed: ((Bool) -> ())? { get set }
    var isSoundOn: Bool { get set }
    var isSoundEnabled: Bool { get set }
    var backgroundPlayer: AVAudioPlayer? { get set }
    var soundEffectPlayer: AVAudioPlayer? { get set }
    func prepareSound()
    func viewDidLoad()
}

class ViewModelImplementation: NSObject, ViewModel {
    init(viewController: ViewController) {
        self.viewController = viewController
    }
    weak var viewController: ViewController?

    var didSoundButtonPressed: ((Bool) -> ())?
    var backgroundPlayer: AVAudioPlayer?
    var soundEffectPlayer: AVAudioPlayer?

    var isSoundOn: Bool = false
    var isSoundEnabled: Bool = false {
        didSet {
            isSoundOn = isSoundEnabled
            self.didSoundButtonPressed?(isSoundEnabled)
            // бизнес-логика
            if isSoundEnabled {
                backgroundPlayer?.play()
            } else {
                backgroundPlayer?.stop()
            }
        }
    }

    func viewDidLoad() {
        prepareSound()
    }

    func prepareSound() {
        if let backgroundAudioFileURL = Bundle.main.url(
            forResource: "Background sound",
            withExtension: "mp3"
        ) {
            do {
                let player = try AVAudioPlayer(contentsOf: backgroundAudioFileURL)
                player.prepareToPlay()
                player.delegate = self
                player.volume = 0.4
                backgroundPlayer = player
            } catch {
                print(error.localizedDescription)
            }
        }
        if let soundEffectAudioFileURL = Bundle.main.url(
            forResource: "Effect sound",
            withExtension: "mp3"
        ) {
            do {
                let player = try AVAudioPlayer(contentsOf: soundEffectAudioFileURL)
                player.prepareToPlay()
                player.delegate = self
                player.volume = 0.5
                soundEffectPlayer = player
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

extension ViewModelImplementation: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if isSoundOn {
            backgroundPlayer?.play()
        } else {
            backgroundPlayer = nil
        }
    }
}
