//
//  String+Localizable.swift
//  Weather
//
//  Created by Володя on 22.07.2021.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
