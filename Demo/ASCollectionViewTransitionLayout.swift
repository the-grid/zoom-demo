//
//  ASCollectionViewTransitionLayout.swift
//  Demo
//
//  Created by Nicholas Velloff on 5/23/16.
//  Copyright © 2016 The Grid. All rights reserved.
//

import Foundation

class ASCollectionViewTransitionLayout: UICollectionViewTransitionLayout {
    
    var ready = false
    override func invalidateLayout() {
        super.invalidateLayout()
        // Prevents a "flicker" when this first gets constructed
        guard transitionProgress > 0 || ready else { return }
        guard let collectionView = collectionView else { return }
        ready = true
        (collectionView as? ASCollectionView)?.relayoutItems()
    }
}