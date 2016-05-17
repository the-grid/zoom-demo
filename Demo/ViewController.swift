//
//  ViewController.swift
//  Demo
//
//  Created by Nicholas Velloff on 5/17/16.
//  Copyright © 2016 The Grid. All rights reserved.
//

import UIKit

class ViewController: ASViewController, ASCollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {

    let viewModel: ViewModel
    let collectionNode: ASCollectionNode
    let layout: ASCollectionViewVerticalLayout
    let horizontalGap: CGFloat = 16
    let verticalGap: CGFloat = 16
    
    
    init(viewModel vm: ViewModel) {
        viewModel = vm
        layout = ASCollectionViewVerticalLayout(horizontalItemCount: 3, horizontalGap: horizontalGap, verticalGap: verticalGap)
        collectionNode = ASCollectionNode(collectionViewLayout: layout)
        super.init(node: collectionNode)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.handlePinch(_:)))
        pinch.delaysTouchesBegan = true
        pinch.delegate = self
        collectionNode.view.addGestureRecognizer(pinch)
        
        collectionNode.delegate = viewModel
        collectionNode.dataSource = viewModel
        
        collectionNode.view.allowsSelection = false
        collectionNode.view.backgroundColor = UIColor.blackColor()
        
        
        // Sets the tuning params that tell the individual ASCellNodes how early to
        // load their additional resources in `override func fetchData()`
        let displayTuning = ASRangeTuningParameters(leadingBufferScreenfuls: 2, trailingBufferScreenfuls: 1)
        let fetchTuning = ASRangeTuningParameters(leadingBufferScreenfuls: 2, trailingBufferScreenfuls: 1)
        collectionNode.setTuningParameters(displayTuning, forRangeType: .Display)
        collectionNode.setTuningParameters(fetchTuning, forRangeType: .FetchData)
        
        // Sets the leading screens to batch load the item list data /item?params
        collectionNode.view.leadingScreensForBatching = 2
    }
    
    var targetCellIndexPath: NSIndexPath?
    var transitionLayout: UICollectionViewTransitionLayout?
    func handlePinch(pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .Began:
            print("Begin Pinch")
            let pinchPoint = pinch.locationInView(collectionNode.view)
            targetCellIndexPath = collectionNode.view.indexPathForItemAtPoint(pinchPoint)
            let currentLayoutHorizontalItemCount = (collectionNode.view.collectionViewLayout as! ASCollectionViewVerticalLayout).horizontalItemCount
            let nextHorizontalCount = pinch.scale < 1 ? currentLayoutHorizontalItemCount + 1 : currentLayoutHorizontalItemCount - 1
            let nextLayout = ASCollectionViewVerticalLayout(horizontalItemCount: nextHorizontalCount, horizontalGap: horizontalGap, verticalGap: verticalGap)
            transitionLayout = collectionNode.view.startInteractiveTransitionToCollectionViewLayout(nextLayout) { completion in
                print("startInteractiveTransitionToCollectionViewLayout Complete")
            }
        case .Changed:
            var scaleFactor: CGFloat = 0
            if pinch.scale < 1 {
                scaleFactor = 1 - pinch.scale
            } else {
                scaleFactor = (pinch.scale - 1) / 2
            }
            transitionLayout?.transitionProgress = min(scaleFactor, 0.99)
            transitionLayout?.invalidateLayout()
            
        case .Ended:
            print("End Pinch")
            if transitionLayout?.transitionProgress > 0.4 {
                collectionNode.view.finishInteractiveTransition()
            } else {
                collectionNode.view.cancelInteractiveTransition()
            }
            transitionLayout = .None
        default: break
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

