//
//  Prediction.swift
//  Autocomplete
//
//  Created by Maciek Grzybowski on 12.07.2017.
//  Copyright © 2017 ncreated. All rights reserved.
//

import Foundation

struct Prediction {
    let predictedText: String
    let matchingRange: Range<String.Index>
}

extension Prediction: Equatable {
    static func ==(lhs: Prediction, rhs: Prediction) -> Bool {
        return lhs.predictedText == rhs.predictedText
            && lhs.matchingRange == rhs.matchingRange
    }
}
