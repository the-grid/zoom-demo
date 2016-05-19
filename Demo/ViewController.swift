//
//  ViewController.swift
//  Demo
//
//  Created by Nicholas Velloff on 5/17/16.
//  Copyright © 2016 The Grid. All rights reserved.
//

import UIKit

extension _ArrayType where Generator.Element == ASCellNode {
    func setNeedsLayout(size: CGSize) {
        for node in self {
            node.frame = CGRect(origin: node.frame.origin, size: size)
            node.setNeedsLayout()
        }
    }
}

class ViewController: ASViewController, UIGestureRecognizerDelegate {

    let viewModel: ViewModel
    let collectionNode: ASCollectionNode
    let layout: ASCollectionViewVerticalLayout
    let horizontalGap: CGFloat = 16
    let verticalGap: CGFloat = 16
    var currentHorizontalCount = 3
    
    init(viewModel vm: ViewModel) {
        viewModel = vm
        layout = ASCollectionViewVerticalLayout(horizontalItemCount: currentHorizontalCount, horizontalGap: horizontalGap, verticalGap: verticalGap)
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
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        collectionNode.view.collectionViewLayout.invalidateLayout()
    }
    
    var targetCellIndexPath: NSIndexPath?
    var transitionLayout: UICollectionViewTransitionLayout?
    var lastState: UIGestureRecognizerState = .Possible
    var cellsToUpdateDuringTransition: [ASCellNode]?
    
    func handlePinch(pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .Began:
            guard lastState == .Possible else { return }
            
            let targetHorizontalCount = pinch.scale < 1 ? currentHorizontalCount + 1 : currentHorizontalCount - 1
            guard targetHorizontalCount > 0 else { return }
            
            lastState = pinch.state
            cellsToUpdateDuringTransition = collectionNode.view.visibleNodes()
            
            let pinchPoint = pinch.locationInView(collectionNode.view)
            targetCellIndexPath = collectionNode.view.indexPathForItemAtPoint(pinchPoint)
            let nextLayout = ASCollectionViewVerticalLayout(horizontalItemCount: targetHorizontalCount, horizontalGap: horizontalGap, verticalGap: verticalGap)
            transitionLayout = collectionNode.view.startInteractiveTransitionToCollectionViewLayout(nextLayout) { [weak self] completion in
                if completion.1 {
                    self?.currentHorizontalCount = targetHorizontalCount
                }
                self?.transitionLayout = .None
                self?.lastState = .Possible
            }
        case .Changed:
            guard lastState == .Began else { return }
            var scaleFactor: CGFloat = 0
            if pinch.scale < 1 {
                scaleFactor = 1 - pinch.scale
            } else {
                scaleFactor = (pinch.scale - 1) / 2
            }
            let progress = min(scaleFactor, 1)
            transitionLayout?.transitionProgress = progress
            
            let ip = NSIndexPath(index: 0)
            guard let transitionPrevSize = transitionLayout?.currentLayout.layoutAttributesForItemAtIndexPath(ip)?.size else { return }
            guard let transitionTargetSize = transitionLayout?.nextLayout.layoutAttributesForItemAtIndexPath(ip)?.size else { return }
            let progressWidth = ((transitionTargetSize.width - transitionPrevSize.width) * progress) + transitionPrevSize.width
            let progressHeight = ((transitionTargetSize.height - transitionPrevSize.height) * progress) + transitionPrevSize.height
            let progressiveSize = CGSize(width: progressWidth, height: progressHeight)
            
//            cellsToUpdateDuringTransition?.setNeedsLayout(progressiveSize)
            viewModel.itemSize = progressiveSize
            collectionNode.view.relayoutAllNodes()
            //Right now reloadData and layoutSubviews manually calls into the ASDataController to relayout the sizes of the collection view nodes. 🙈
            // https://github.com/facebook/AsyncDisplayKit/issues/691
            // https://github.com/facebook/AsyncDisplayKit/issues/866
            
        case .Ended:
            guard lastState == .Began else { return }
            lastState = pinch.state
            if transitionLayout?.transitionProgress > 0.4 {
                collectionNode.view.finishInteractiveTransition()
            } else {
                collectionNode.view.cancelInteractiveTransition()
            }
        default: break
        }
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

