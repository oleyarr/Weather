//
//  ViewModel.swift
//  Weather
//
//  Created by Володя on 18.08.2021.
//

import Foundation

protocol ViewModel {
    var didSoundButtonPressed: ((Bool) -> ())? { get set }
    var isSoundEnabled: Bool? { get set }
}

class ViewModelImplementation: ViewModel {
    var didSoundButtonPressed: ((Bool) -> ())?
    weak var viewController: ViewController?

    init(viewController: ViewController) {
        self.viewController = viewController
    }

     var isSoundEnabled: Bool? = false {
        didSet {
            if let isSoundEnabled = isSoundEnabled {
                self.didSoundButtonPressed?(isSoundEnabled)
                // бизнес-логика
                if isSoundEnabled {
                    viewController?.backgroundPlayer?.play()
                } else {
                    viewController?.backgroundPlayer?.stop()
                }
            }
        }
    }
}
