//
//  ASCollectionViewVerticalLayout.swift
//  Demo
//
//  Created by Nicholas Velloff on 5/17/16.
//  Copyright © 2016 The Grid. All rights reserved.
//

import Foundation

class ASCollectionViewVerticalLayout: UICollectionViewLayout {
    
    let horizontalItemCount: Int
    let horizontalGap: CGFloat
    let verticalGap: CGFloat
    var itemSize = CGSizeZero
    
    var cardsTotalWidth: CGFloat = 0
    var horizontalGapCount: CGFloat = 0
    var horizontalInsetTotal: CGFloat = 0
    var hCenterOffset: CGFloat = 0
    
    required init(horizontalItemCount hic: Int, horizontalGap hg: CGFloat, verticalGap vg: CGFloat) {
        horizontalItemCount = hic
        horizontalGap = hg
        verticalGap = vg
        super.init()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareLayout() {
        guard let collectionView = self.collectionView else { fatalError() }
        
        itemSize = getItemSize(viewBounds: collectionView.bounds)
        
        cardsTotalWidth = itemSize.width * CGFloat(horizontalItemCount)
        horizontalGapCount = horizontalGap * CGFloat(horizontalItemCount - 1)
        horizontalInsetTotal = collectionView.contentInset.left + collectionView.contentInset.right
        hCenterOffset = (collectionView.bounds.width - cardsTotalWidth - horizontalGapCount - horizontalInsetTotal) / 2
        
        super.prepareLayout()
    }
    
    
    var cachedAtts = [NSIndexPath: UICollectionViewLayoutAttributes]()
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        // Ensure all items attributes are cached
        
        let itemCount = getItemCount()
        for index in 0 ..< itemCount {
            let isCached = cachedAtts.contains { $0.0.item == index}
            if !isCached {
                let indexPath = NSIndexPath(forItem: index, inSection: 0)
                if let att = layoutAttributesForItemAtIndexPath(indexPath) {
                    cachedAtts[att.indexPath] = att
                }
            }
        }
        
        let intersectingAttributes = cachedAtts.flatMap { $0.1 }
            .filter { $0.frame.intersects(rect) }
        
        return intersectingAttributes
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
                
        guard cachedAtts.indexForKey(indexPath) == nil else { return cachedAtts[indexPath] }
        
        let att = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        let col = indexPath.item % horizontalItemCount
        let row = indexPath.item / horizontalItemCount
        
        var x = CGFloat(col) * itemSize.width
        var y = CGFloat(row) * itemSize.height
        
        // mind the gaps
        x += CGFloat(col) * horizontalGap
        y += CGFloat(row) * verticalGap
        
        // mind the final horizonal centering
        x += hCenterOffset
        
        let rect = CGRect(x: x, y: y, width: itemSize.width, height: itemSize.height)
        att.frame = rect
        att.indexPath = indexPath
        att.size = itemSize
        att.bounds = CGRect(origin: CGPointZero, size: itemSize)
        
        return att
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    override func collectionViewContentSize() -> CGSize {
        guard let atts = layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: getItemCount(), inSection: 0)) else { return CGSizeZero }
        guard let collectionView = self.collectionView else { return CGSizeZero }
        let w = collectionView.bounds.width
        let h = atts.frame.origin.y + atts.frame.height
        return CGSize(width: w, height: h)
    }
    
    func getItemCount() -> Int {
        guard collectionView?.numberOfSections() > 0 else { return 0 }
        guard let itemsCount = collectionView?.numberOfItemsInSection(0) else { return 0 }
        return itemsCount
    }
    
    func getItemSize(viewBounds viewBounds: CGRect) -> CGSize {
        let availWidth = viewBounds.width - CGFloat(horizontalGap * CGFloat(horizontalItemCount - 1))
        let maxItemWidth = max(availWidth / CGFloat(horizontalItemCount), 0)
        let size = CGSize(width: maxItemWidth, height: maxItemWidth)
        return size
    }
}