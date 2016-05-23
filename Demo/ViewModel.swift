//
//  ViewModel.swift
//  Demo
//
//  Created by Nicholas Velloff on 5/17/16.
//  Copyright © 2016 The Grid. All rights reserved.
//

import Foundation

class ViewModel: NSObject, ASCollectionDelegate, ASCollectionDataSource {
    
    var loadedItemCount = 30
    let totalItemCount = 200
    let maxAdditionalToLoad = 30
    var itemSize = CGSizeZero
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section == 0 else { return 0 }
        return loadedItemCount
    }
    
    // MARK: ASCollectionDataSource delegate methods
    
    func collectionViewLockDataSource(collectionView: ASCollectionView) {
        // print("collectionViewLockDataSource")
    }
    
    func collectionViewUnlockDataSource(collectionView: ASCollectionView) {
        // print("collectionViewUnlockDataSource")
    }
    
    func collectionView(collectionView: ASCollectionView, constrainedSizeForNodeAtIndexPath indexPath: NSIndexPath) -> ASSizeRange {
        guard let layout = collectionView.collectionViewLayout as? ASCollectionViewVerticalLayout else {
            return ASSizeRange(min: itemSize, max: itemSize)
        }
        let size = layout.getItemSize(viewBounds: collectionView.bounds)
        return ASSizeRange(min: size, max: size)
    }
    
    func collectionView(collectionView: ASCollectionView, nodeBlockForItemAtIndexPath indexPath: NSIndexPath) -> ASCellNodeBlock {
        return {
            return PostASCellNode(path: indexPath)
        }
    }
    
    
    // MARK: ASCollectionDelegate delegate methods
    func shouldBatchFetchForCollectionView(collectionView: ASCollectionView) -> Bool {
        return loadedItemCount < totalItemCount
    }
    
    func collectionView(collectionView: ASCollectionView, willBeginBatchFetchWithContext context: ASBatchContext) {
        
        let currentCount = loadedItemCount
        let numToInsert = min(maxAdditionalToLoad, totalItemCount - currentCount)
        let pathsToInsert: [NSIndexPath] = {
            var paths = [NSIndexPath]()
            for i in 0...numToInsert {
                paths.append(NSIndexPath(forRow: currentCount + i, inSection: 0))
            }
            return paths
        }()
        loadedItemCount += numToInsert
        
        // Insert data into collection view
        dispatch_async(dispatch_get_main_queue(),{
            collectionView.performBatchUpdates({
                
                collectionView.insertItemsAtIndexPaths(pathsToInsert)
                
                }, completion: { complete in
                    // Properly finish the batch fetch
                    context.completeBatchFetching(true)
            })
        })
    }
    
    func getAllLoadedPaths() -> [NSIndexPath] {
        var paths = [NSIndexPath]()
        for i in 0 ..< loadedItemCount {
            paths.append(NSIndexPath(forRow: i, inSection: 0))
        }
        return paths
    }
}
