//
//  SearchPredictionCell.swift
//  Autocomplete
//
//  Created by Maciek Grzybowski on 03.07.2017.
//  Copyright © 2017 ncreated. All rights reserved.
//

import UIKit

class SearchPredictionCell: UITableViewCell {

    func configure(with prediction: Prediction) {
        textLabel?.attributedText = higlightedTextFor(prediction: prediction)
    }

    private func higlightedTextFor(prediction: Prediction) -> NSAttributedString {
        let higlightedPrefix = prediction.predictedText.substring(with: prediction.matchingRange)
        let higlightedRange = (prediction.predictedText as NSString).range(of: higlightedPrefix)
        let higlightColor = UIColor(red: 0.3, green: 0.89, blue: 0.84, alpha: 0.5)
 
        let textWithHiglight = NSMutableAttributedString(string: prediction.predictedText)
        textWithHiglight.addAttribute(NSBackgroundColorAttributeName, value: higlightColor, range: higlightedRange)

        return textWithHiglight
    }
}
