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
    
    var transitionLayout: UICollectionViewTransitionLayout?
    var lastState: UIGestureRecognizerState = .Possible
    var cellsToUpdateDuringTransition: [ASCellNode]?
    var transitionPrevSize = CGSizeZero
    var transitionNextSize = CGSizeZero
    
    func handlePinch(pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .Began:
            guard lastState == .Possible else { return }
            
            let targetHorizontalCount = pinch.scale < 1 ? currentHorizontalCount + 1 : currentHorizontalCount - 1
            guard targetHorizontalCount > 0 else { return }
            
            lastState = pinch.state
            
            let loadedPaths = viewModel.getAllLoadedPaths()
            cellsToUpdateDuringTransition = loadedPaths.map { return collectionNode.view.nodeForItemAtIndexPath($0) }
            
            let pinchPoint = pinch.locationInView(collectionNode.view)
            
            let nextLayout = ASCollectionViewVerticalLayout(horizontalItemCount: targetHorizontalCount, horizontalGap: horizontalGap, verticalGap: verticalGap)
            
            nextLayout.targetCellIndexPath = collectionNode.view.indexPathForItemAtPoint(pinchPoint)
            
            transitionPrevSize = (collectionNode.view.collectionViewLayout as? ASCollectionViewVerticalLayout)?.getItemSize(viewBounds: collectionNode.bounds) ?? CGSizeZero
            
            transitionNextSize = nextLayout.getItemSize(viewBounds: collectionNode.bounds)
            
            transitionLayout = collectionNode.view.startInteractiveTransitionToCollectionViewLayout(nextLayout) { [weak self] completion in
                if completion.1 {
                    self?.currentHorizontalCount = targetHorizontalCount
                }
                self?.transitionLayout = .None
                self?.lastState = .Possible
                
                /* trying to trigger data fetch
                 guard let floor = self?.view.bounds.height else { return }
                 self?.collectionNode.view.setContentOffset(CGPoint(x: 0, y: floor), animated: true)
                 */
            }
            
        //Right now reloadData and layoutSubviews manually calls into the ASDataController to relayout the sizes of the collection view nodes.
        case .Changed:
            guard lastState == .Began else { return }
            var scaleFactor: CGFloat = 0
            if pinch.scale < 1 {
                scaleFactor = 1 - pinch.scale
            } else {
                scaleFactor = (pinch.scale - 1) / 2
            }
            
            let progress = min(scaleFactor, 1)
            
            let progressWidth = ((transitionNextSize.width - transitionPrevSize.width) * progress) + transitionPrevSize.width
            let progressHeight = ((transitionNextSize.height - transitionPrevSize.height) * progress) + transitionPrevSize.height
            let progressiveSize = CGSize(width: progressWidth, height: progressHeight)
            
            transitionLayout?.transitionProgress = progress
            viewModel.itemSize = progressiveSize
            transitionLayout?.invalidateLayout()
        case .Ended:
            guard lastState == .Began else { return }
            guard let progress = transitionLayout?.transitionProgress else { return }
            lastState = pinch.state
            let cancelInteractiveTransition = progress < 0.4
            
            viewModel.itemSize = cancelInteractiveTransition ? transitionPrevSize : transitionNextSize
            
            cancelInteractiveTransition ? collectionNode.view.cancelInteractiveTransition() : collectionNode.view.finishInteractiveTransition()
            
        default: break
        }
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

