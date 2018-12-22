//
//  ViewController.swift
//  3d-tap
//
//  Created by Anton Skopin on 23/12/2018.
//  Copyright © 2018 cuberto. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 50
    }
    
    var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter
    }
    var startDate: Date {
        return dateFormatter.date(from: "11:00") ?? Date()
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "test", for: indexPath)
        if let cell = cell as? CB3DSelectCell {
            cell.lblTime.text = dateFormatter.string(from: startDate.addingTimeInterval(TimeInterval(60*30*indexPath.item)))
            cell.lblPrice.text = "$\(Int.random(in: 1...12) * 10)"
            cell.offsetDirection = (indexPath.item % 2 == 0) ? .right : .left
            if cell.isSelected {
                cell.select(animated: false)
            } else {
                cell.deselect(animated: false)
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CB3DSelectCell {
            cell.select(animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CB3DSelectCell {
            cell.deselect(animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (view.frame.width - 1)/2.0, height: (view.frame.width - 1)/2.0)
    }
    
}

