//
//  AutocompleteProvider.swift
//  Autocomplete
//
//  Created by Maciek Grzybowski on 04.07.2017.
//  Copyright © 2017 ncreated. All rights reserved.
//

import RxSwift

/// Protocol to be implemented by different autocomplete providers.
protocol AutocompleteProvider {

    /// Returns `Observable` of predictions for given `text` input.
    ///
    /// Note: returned observable should emits `.error` if provider meets a problem.
    func autocomplete(text: String) -> Observable<[Prediction]>
}
