//
//  AutocompleteResult.swift
//  Autocomplete
//
//  Created by Maciek Grzybowski on 15.07.2017.
//  Copyright © 2017 ncreated. All rights reserved.
//

import Foundation

enum AutocompleteResult {
    case predictions([Prediction])
    case error(Error)
}

extension AutocompleteResult {
    var predictions: [Prediction]? {
        switch self {
        case .predictions(let predictions):
            return predictions
        case .error:
            return nil
        }
    }

    var error: Error? {
        switch self {
        case .predictions:
            return nil
        case .error(let error):
            return error
        }
    }
}
