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
        let nib = UINib(nibName: "AccountCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "AccountCell")
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 50.0
    }
    
    @objc func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        
        let longPress = gestureRecognizer as! UILongPressGestureRecognizer
        let state = longPress.state
        let locationInView = longPress.location(in: self.tableView)
        guard let indexPath = self.tableView.indexPathForRow(at: locationInView) else {
            return
        }
        
        switch state {
        case UIGestureRecognizerState.began:
            self.movingCellInitialIndexPath = indexPath
            guard let cell = self.tableView.cellForRow(at: indexPath) else {
                return
            }
            let snapshotView = snapshotOfCell(cell)
            movingCellSnapshotView = snapshotView
            var center = cell.center
            snapshotView.center = center
            snapshotView.alpha = 0.0
            tableView.addSubview(snapshotView)
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                center.y = locationInView.y
                self.movingCellIsAnimating = true
                snapshotView.center = center
                snapshotView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                snapshotView.alpha = 0.98
                cell.alpha = 0.0
            }, completion: { (finished) -> Void in
                if finished {
                    self.movingCellIsAnimating = false
                    if self.movingCellNeedsToShow {
                        self.movingCellNeedsToShow = false
                        UIView.animate(withDuration: 0.25, animations: { () -> Void in
                            cell.alpha = 1
                        })
                    } else {
                        cell.isHidden = true
                    }
                }
            })
        case UIGestureRecognizerState.changed:
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
        default:
            guard let initialIndexPath = self.movingCellInitialIndexPath,
                let cell = self.tableView.cellForRow(at: initialIndexPath),
                let snapshotView = self.movingCellSnapshotView else {
                return
            }

            if self.movingCellIsAnimating {
                self.movingCellNeedsToShow = true
            } else {
                cell.isHidden = false
                cell.alpha = 0.0
            }
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                snapshotView.center = cell.center
                snapshotView.transform = CGAffineTransform.identity
                snapshotView.alpha = 0.0
                cell.alpha = 1.0
            }, completion: { (finished) -> Void in
                if finished {
                    print(self.itemsArray)
                    self.movingCellInitialIndexPath = nil
                    self.movingCellSnapshotView!.removeFromSuperview()
                    self.movingCellSnapshotView = nil
                }
            })
        }
    }
    
    func snapshotOfCell(_ inputView: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        UIGraphicsEndImageContext()
        let snapshotView : UIView = UIImageView(image: image)
        snapshotView.layer.masksToBounds = false
        snapshotView.layer.cornerRadius = 0.0
        snapshotView.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
        snapshotView.layer.shadowRadius = 5.0
        snapshotView.layer.shadowOpacity = 0.4
        return snapshotView
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell") as! AccountCell
        cell.titleLabel.text = itemsArray[indexPath.section]
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == itemsArray.count - 1 {
            return 10
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
