//
//  SearchViewController.swift
//  Autocomplete
//
//  Created by Maciek Grzybowski on 03.07.2017.
//  Copyright © 2017 ncreated. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SearchViewController: UITableViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet var noResultsView: UIView!
    @IBOutlet var errorView: UIView!
    @IBOutlet weak var errorMessageLabel: UILabel!

    private let disposeBag = DisposeBag()
    private let autocomplete = Autocomplete(provider: CountryAutocompleteProvider())

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = nil
        tableView.dataSource = nil
        tableView.backgroundView = nil

        setUpAutocomplete()
    }

    private func setUpAutocomplete() {
        guard let tableView = self.tableView, let errorView = self.errorView, let noResultsView = self.noResultsView else {
            return
        }

        // Define intput stream
        let inputText = searchBar.rx.text
            .asObservable()
            .flatMap { $0.map(Observable.just) ?? Observable.empty() } // .unwrap() if using `RxSwiftExt`

        // Create autocomplete streams
        let (results, isLoading) = autocomplete.autocomplete(text: inputText)

        // Emits `[Prediction]` when new results are available (or `[]` if no results or error)
        let predictions: Driver<[Prediction]> = results
            .map { $0.predictions ?? [] }

        // Emits error message (`String`) if error occured
        let errorMessage: Driver<String> = results
            .flatMap { $0.error.map(Driver.just) ?? Driver.empty() }
            .map { "\($0)" }

        // Bind predictions to table view data source
        predictions
            .drive(tableView.rx.items(cellIdentifier: "search-prediction", cellType: SearchPredictionCell.self)) { (_, prediction, cell) in
                cell.configure(with: prediction)
            }
            .disposed(by: disposeBag)

        // Bind error messages to label
        errorMessage
            .drive(errorMessageLabel.rx.text)
            .disposed(by: disposeBag)

        // Emits background view to be set for `tableView`
        let backgroundView = results
            .map { result -> UIView? in
                switch result {
                case .predictions(let predictions) where predictions.count == 0:
                    return noResultsView // if 0 predictions, emit `noResultsView`
                case .error:
                    return errorView // if error occured, emit `errorView`
                default:
                    return nil // otherwise set `nil` table background view
                }
            }

        // Bind background to table view
        backgroundView
            .drive(onNext: { tableView.backgroundView = $0 })
            .disposed(by: disposeBag)

        // Bind loading state to network activity indicator
        isLoading
            .drive(UIApplication.shared.rx.isNetworkActivityIndicatorVisible)
            .disposed(by: disposeBag)
    }
}
