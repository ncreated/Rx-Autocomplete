//
//  Autocomplete.swift
//  Autocomplete
//
//  Created by Maciek Grzybowski on 03.07.2017.
//  Copyright © 2017 ncreated. All rights reserved.
//

import RxSwift
import RxCocoa

final class Autocomplete {

    // MARK: - Properties

    private let provider: AutocompleteProvider

    // MARK: - Initializers

    init(provider: AutocompleteProvider) {
        self.provider = provider
    }

    // MARK: - Public

    func autocomplete(text: Observable<String?>) -> (result: Driver<AutocompleteResult>, isBusy: Driver<Bool>) {
        let provider = self.provider
        let isLoadingSubject = PublishSubject<Bool>()

        let query: Observable<String> = text
            .flatMap { $0.map(Observable.just) ?? Observable.empty() }

        let result: Driver<AutocompleteResult> = query
            .do(onNext: { _ in isLoadingSubject.onNext(true) })
            .flatMapLatest { query -> Observable<AutocompleteResult> in
                provider
                    .autocomplete(text: query)
                    .map { .predictions($0) }
                    .catchError { .just(.error($0)) }
            }
            .asDriver(onErrorJustReturn: .predictions([]))
            .do(onNext: { _ in isLoadingSubject.onNext(false) })


        let isLoading = isLoadingSubject
            .asDriver(onErrorJustReturn: false)

        return (result: result, isBusy: isLoading)
    }
}
