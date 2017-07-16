//
//  AutocompleteTests.swift
//  AutocompleteTests
//
//  Created by Maciek Grzybowski on 30.06.2017.
//  Copyright © 2017 ncreated. All rights reserved.
//

import XCTest
import RxSwift
import RxCocoa
@testable import Autocomplete

private final class MockAutocompleteProvider: AutocompleteProvider {

    var didCallAutocomplete: ((String) -> Void)?

    private let subject = PublishSubject<[Prediction]>()

    // MARK: - AutocompleteProvider

    func autocomplete(text: String) -> Observable<[Prediction]> {
        didCallAutocomplete?(text)
        return subject.asObservable()
    }

    // MARK: - Simulating

    func simulate(predictions: [Prediction]) {
        subject.onNext(predictions)
    }

    func simulate(error: Error) {
        subject.onError(error)
    }
}

private final class SimulatedInput {

    private let subject = PublishSubject<String?>()

    var text: Observable<String?> { return subject.asObservable() }

    // MARK: - Simulating

    func simulate(text: String) {
        subject.onNext(text)
    }
}

private enum MockError: Error {
    case mockError
}

class AutocompleteTests: XCTestCase {

    private let mockPrediction = Prediction(predictedText: "Italy",
                                            matchingRange: ("It".startIndex..<"It".endIndex))

    func testItEmitsPredictionsResult() {
        let disposeBag = DisposeBag()
        let provider = MockAutocompleteProvider()
        let autocomplete = Autocomplete(provider: provider)
        let input = SimulatedInput()
        let mockPrediction = self.mockPrediction
        let expectation = self.expectation(description: "will emit result")

        let (result, _) = autocomplete.autocomplete(text: input.text)

        result
            .drive(onNext: { result in
                if case let .predictions(predictions) = result {
                    XCTAssertEqual(predictions, [mockPrediction])
                } else {
                    XCTFail()
                }

                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        input.simulate(text: "Italy")
        provider.simulate(predictions: [mockPrediction])

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testItEmitsErrorResult() {
        let disposeBag = DisposeBag()
        let provider = MockAutocompleteProvider()
        let autocomplete = Autocomplete(provider: provider)
        let input = SimulatedInput()
        let expectation = self.expectation(description: "will emit result")

        let (result, _) = autocomplete.autocomplete(text: input.text)

        result
            .drive(onNext: { result in
                if case let .error(error) = result {
                    XCTAssertEqual(String(describing: error), String(describing: MockError.mockError))
                } else {
                    XCTFail()
                }

                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        input.simulate(text: "Italy")
        provider.simulate(error: MockError.mockError)

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testItStartsLoadingAfterReceivingInput() {
        let disposeBag = DisposeBag()
        let provider = MockAutocompleteProvider()
        let autocomplete = Autocomplete(provider: provider)
        let input = SimulatedInput()
        let expectation = self.expectation(description: "will emit loading state")

        let (result, isLoading) = autocomplete.autocomplete(text: input.text)

        result.drive().disposed(by: disposeBag)
        isLoading
            .drive(onNext: { isLoading in
                XCTAssertTrue(isLoading)
                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        input.simulate(text: "Italy")

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testItStopsLoadingAfterReceivingPredictions() {
        let disposeBag = DisposeBag()
        let provider = MockAutocompleteProvider()
        let autocomplete = Autocomplete(provider: provider)
        let input = SimulatedInput()
        let expectation = self.expectation(description: "will emit loading state twice")
        expectation.expectedFulfillmentCount = 2

        let (result, isLoading) = autocomplete.autocomplete(text: input.text)

        result.drive().disposed(by: disposeBag)

        var recordedIsLoadingValues: [Bool] = []
        isLoading
            .drive(onNext: { isLoading in
                recordedIsLoadingValues.append(isLoading)
                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        input.simulate(text: "Italy")
        provider.simulate(predictions: [mockPrediction])

        waitForExpectations(timeout: 0.5, handler: nil)

        XCTAssertEqual(recordedIsLoadingValues, [true, false])
    }

    func testItStopsLoadingAfterReceivingError() {
        let disposeBag = DisposeBag()
        let provider = MockAutocompleteProvider()
        let autocomplete = Autocomplete(provider: provider)
        let input = SimulatedInput()
        let expectation = self.expectation(description: "will emit loading state twice")
        expectation.expectedFulfillmentCount = 2

        let (result, isLoading) = autocomplete.autocomplete(text: input.text)

        result.drive().disposed(by: disposeBag)

        var recordedIsLoadingValues: [Bool] = []
        isLoading
            .drive(onNext: { isLoading in
                recordedIsLoadingValues.append(isLoading)
                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        input.simulate(text: "Italy")
        provider.simulate(error: MockError.mockError)

        waitForExpectations(timeout: 0.5, handler: nil)

        XCTAssertEqual(recordedIsLoadingValues, [true, false])
    }

    // MARK: - Test internals and subscription model

    func testItAsksProviderToAutocomplete() {
        let disposeBag = DisposeBag()
        let provider = MockAutocompleteProvider()
        let autocomplete = Autocomplete(provider: provider)
        let input = SimulatedInput()
        let expectation = self.expectation(description: "provider will autocomplete")

        provider.didCallAutocomplete = { providerInput in
            XCTAssertEqual(providerInput, "Italy")
            expectation.fulfill()
        }

        let (result, isLoading) = autocomplete.autocomplete(text: input.text)

        result.drive().disposed(by: disposeBag)
        isLoading.drive().disposed(by: disposeBag)

        input.simulate(text: "Italy")

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testItAsksProviderToAutocompleteOnlyOnceIfMultipleSubscriptionsAreMade() {
        let disposeBag = DisposeBag()
        let provider = MockAutocompleteProvider()
        let autocomplete = Autocomplete(provider: provider)
        let input = SimulatedInput()
        let expectation = self.expectation(description: "provider will autocomplete once")

        provider.didCallAutocomplete = { providerInput in
            XCTAssertEqual(providerInput, "Italy")
            expectation.fulfill()
        }

        let (result, isLoading) = autocomplete.autocomplete(text: input.text)

        // First subscriptions
        result.drive().disposed(by: disposeBag)
        isLoading.drive().disposed(by: disposeBag)

        // More subscriptions
        result.drive().disposed(by: disposeBag)
        isLoading.drive().disposed(by: disposeBag)

        input.simulate(text: "Italy")

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testItKeepsEmittingAfterProviderError() {
        let disposeBag = DisposeBag()
        let provider = MockAutocompleteProvider()
        let autocomplete = Autocomplete(provider: provider)
        let input = SimulatedInput()
        let expectation = self.expectation(description: "will emit result 3 times")
        expectation.expectedFulfillmentCount = 3

        let (result, _) = autocomplete.autocomplete(text: input.text)

        result
            .drive(onNext: { _ in
                expectation.fulfill()

            })
            .disposed(by: disposeBag)

        input.simulate(text: "Ita")
        provider.simulate(error: MockError.mockError)
        input.simulate(text: "Ital")
        provider.simulate(predictions: [mockPrediction])
        input.simulate(text: "Italy")
        provider.simulate(predictions: [mockPrediction])

        waitForExpectations(timeout: 0.5, handler: nil)
    }
}
