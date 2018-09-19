//
//  ViewController.swift
//  TableView Reorder
//
//  Created by William Peroche on 19/09/18.
//  Copyright © 2018 William Peroche. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var itemsArray = ["1","2","3","4","5","6","7","8"]
    
    var movingCellSnapshotView: UIView?
    var movingCellIsAnimating = false
    var movingCellNeedsToShow = false
    var movingCellInitialIndexPath: IndexPath?
    
    
    let kAnimationDuration: TimeInterval = 0.25
    let kVisibleAlpha: CGFloat = 1
    let kInvisibleAlpha: CGFloat = 0
    let kTranslucentAlpha: CGFloat = 0.98
    let kShadowOffSet = CGSize(width: -5.0, height: 0.0)
    let kShadowRadius: CGFloat = 5.0
    let kShadowOpacity: Float = 0.5
    let kContextScale: CGFloat = 0
    
    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupTableView()
        setupGesture()
    }

    func setupGesture() {
        let longpress = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.longPressGestureRecognized(_:)))
        self.tableView.addGestureRecognizer(longpress)
    }
    
    func setupTableView() {
        let nib = UINib(nibName: AccountCell.kAccountCellIdentifier, bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: AccountCell.kAccountCellIdentifier)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 50.0
    }
    
    @objc func longPressGestureRecognized(_ gestureRecognizer: UILongPressGestureRecognizer) {
        
        let locationInView = gestureRecognizer.location(in: self.tableView)
        guard let indexPath = self.tableView.indexPathForRow(at: locationInView) else {
            self.finalizeReorderOfCell()
            return
        }
        
        switch gestureRecognizer.state {
        case UIGestureRecognizerState.began:
            self.createSnapshotOfMovingCell(indexPath: indexPath, locationInView: locationInView)
            
        case UIGestureRecognizerState.changed:
            self.updateModelWithMovingCell(indexPath: indexPath, locationInView: locationInView)
            
        default:
            self.finalizeReorderOfCell()
        }
    }
    
    func snapshotOfCell(_ inputView: UITableViewCell) -> UIView {
        
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, self.kContextScale)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        UIGraphicsEndImageContext()
        let snapshotView : UIView = UIImageView(image: image)
        snapshotView.layer.masksToBounds = false
        snapshotView.layer.shadowOffset = self.kShadowOffSet
        snapshotView.layer.shadowRadius = self.kShadowRadius
        snapshotView.layer.shadowOpacity = self.kShadowOpacity
        
        return snapshotView
    }
    
    func createSnapshotOfMovingCell(indexPath: IndexPath, locationInView: CGPoint) {
        self.movingCellInitialIndexPath = indexPath
        guard let cell = self.tableView.cellForRow(at: indexPath) else {
            return
        }
        let snapshotView = snapshotOfCell(cell)
        movingCellSnapshotView = snapshotView
        let center = cell.center
        snapshotView.center = center
        snapshotView.alpha = self.kInvisibleAlpha
        self.tableView.addSubview(snapshotView)
        UIView.animate(withDuration: self.kAnimationDuration, animations: { [weak self] () -> Void in
            guard let strongSelf = self else {
                return
            }
            strongSelf.movingCellIsAnimating = true
            snapshotView.center = center
            snapshotView.alpha = strongSelf.kVisibleAlpha
            cell.alpha = strongSelf.kInvisibleAlpha
        }, completion: { [weak self] (finished) -> Void in
            guard let strongSelf = self else {
                return
            }
            
            if finished {
                strongSelf.movingCellIsAnimating = false
                if strongSelf.movingCellNeedsToShow {
                    strongSelf.movingCellNeedsToShow = false
                    UIView.animate(withDuration: strongSelf.kAnimationDuration, animations: { () -> Void in
                        cell.alpha = strongSelf.kVisibleAlpha
                    })
                } else {
                    cell.isHidden = true
                }
            }
        })
    }
    
    func updateModelWithMovingCell(indexPath: IndexPath, locationInView: CGPoint) {
        guard let snapshotView = self.movingCellSnapshotView,
            let intialIndexPath = self.movingCellInitialIndexPath else {
                return
        }
        var center = snapshotView.center
        center.y = locationInView.y
        snapshotView.center = center
        if indexPath != intialIndexPath {
            self.itemsArray.insert(self.itemsArray.remove(at: intialIndexPath.section), at: indexPath.section)
            self.tableView.moveSection(intialIndexPath.section, toSection: indexPath.section)
            self.movingCellInitialIndexPath = indexPath
        }
    }
    
    func finalizeReorderOfCell() {
        guard let initialIndexPath = self.movingCellInitialIndexPath,
            let cell = self.tableView.cellForRow(at: initialIndexPath),
            let snapshotView = self.movingCellSnapshotView else {
                return
        }
        
        if self.movingCellIsAnimating {
            self.movingCellNeedsToShow = true
        } else {
            cell.isHidden = false
            cell.alpha = self.kInvisibleAlpha
        }
        UIView.animate(withDuration: self.kAnimationDuration, animations: { [weak self] () -> Void in
            guard let strongSelf = self else {
                return
            }
            
            snapshotView.center = cell.center
            snapshotView.transform = CGAffineTransform.identity
            snapshotView.alpha = strongSelf.kInvisibleAlpha
            cell.alpha = strongSelf.kVisibleAlpha
        }, completion: {  [weak self] (finished) -> Void in
            guard let strongSelf = self else {
                return
            }

            if finished {
                strongSelf.movingCellInitialIndexPath = nil
                snapshotView.removeFromSuperview()
                strongSelf.movingCellSnapshotView = nil
            }
        })
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return itemsArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AccountCell.kAccountCellIdentifier) as! AccountCell
        cell.titleLabel.text = itemsArray[indexPath.section]
        cell.titleLabel.textColor = UIColor(red: 0.1, green: 0.6, blue: 0.4, alpha: 1)
        cell.selectionStyle = .none
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == itemsArray.count - 1 {
            return 0
        }
        return 5
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 10
        }
        return 5
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print(itemsArray[indexPath.section])
    }
}
