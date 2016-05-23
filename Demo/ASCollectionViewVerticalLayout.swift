//
//  ASCollectionViewVerticalLayout.swift
//  Demo
//
//  Created by Nicholas Velloff on 5/17/16.
//  Copyright © 2016 The Grid. All rights reserved.
//

class ASCollectionViewVerticalLayout: UICollectionViewLayout {
    
    let horizontalItemCount: Int
    let horizontalGap: CGFloat
    let verticalGap: CGFloat
    var itemSize = CGSizeZero
    
    var cardsTotalWidth: CGFloat = 0
    var horizontalGapCount: CGFloat = 0
    var horizontalInsetTotal: CGFloat = 0
    var hCenterOffset: CGFloat = 0
    var targetCellIndexPath: NSIndexPath?
    
    private var cachedAtts = [Int: UICollectionViewLayoutAttributes]()
    
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
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        //        print("layoutAttributesForElementsInRect \(rect)")
        
        let itemCount = getItemCount()
        for index in 0 ..< itemCount {
            let isCached = cachedAtts.contains { $0.0 == index}
            if !isCached {
                let indexPath = NSIndexPath(forItem: index, inSection: 0)
                if let att = layoutAttributesForItemAtIndexPath(indexPath) {
                    cachedAtts[index] = att
                }
            }
        }
        
        let intersectingAttributes = cachedAtts.flatMap { $0.1 }
            .filter { $0.frame.intersects(rect) }
        
        return intersectingAttributes
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        
        guard cachedAtts.indexForKey(indexPath.item) == nil else { return cachedAtts[indexPath.item] }
        
        //        print("new layoutAttributesForItemAtIndexPath \(indexPath.item)")
        
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
        att.center = rect.center()
        
        return att
    }
    
    /*
     override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
     //
     }
     
     override func layoutAttributesForDecorationViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
     //
     }
     */
    
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return false
    }
    
    
    override func invalidateLayout() {
        //        print("ASCollectionViewVerticalLayout invalidateLayout()")
        cachedAtts.removeAll()
        super.invalidateLayout()
    }
    
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
        guard let collectionView = self.collectionView else { return proposedContentOffset }
        guard let indexPath = targetCellIndexPath else { return proposedContentOffset }
        guard let cellAttribute = layoutAttributesForItemAtIndexPath(indexPath) else { return proposedContentOffset }
        
        // must use default scroll destination if content doesnt need to scroll
        let totalContentSize = collectionViewContentSize()
        let visibleFrameSize = collectionView.bounds
        
        guard totalContentSize.height >= visibleFrameSize.height else { return proposedContentOffset }
        
        var optimal = cellAttribute.center.y - (visibleFrameSize.height / 2)
        
        if optimal < 0 {
            optimal = 0
        }
        if optimal > totalContentSize.height - visibleFrameSize.height - collectionView.contentInset.top {
            optimal = totalContentSize.height - visibleFrameSize.height - collectionView.contentInset.top
        }
        
        let pt = CGPoint(x: proposedContentOffset.x, y: optimal)
        targetCellIndexPath = nil
        return pt
    }
    
    override func collectionViewContentSize() -> CGSize {
        guard let atts = layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: getItemCount() - 1, inSection: 0)) else { return CGSizeZero }
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