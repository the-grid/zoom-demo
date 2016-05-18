//
//  PostASCellNode.swift
//  Demo
//
//  Created by Nicholas Velloff on 5/17/16.
//  Copyright © 2016 The Grid. All rights reserved.
//

import Foundation

class PostASCellNode: ASCellNode {
    
    let path: NSIndexPath
    
    required init(path p: NSIndexPath) {
        path = p
        super.init()
    }
    override func didLoad() {
        super.didLoad()
        backgroundColor = UIColor.purpleColor()
    }
    
    // Layout all the things
    override func layoutSpecThatFits(constrainedSize: ASSizeRange) -> ASLayoutSpec {
        // print("layoutSpecThatFits: \(constrainedSize)")
        let spec = ASStaticLayoutSpec()
        return spec
    }
    
    // stuff we dont lay out in layoutSpecThatFits
    override func layout() {
        super.layout()
    }
    
    override func visibilityDidChange(isVisible: Bool) {
        // print("visibilityDidChange \(isVisible)")
        super.visibilityDidChange(isVisible)
    }
    
    /**
     * @abstract Indicates that the node should fetch any external data, such as images.
     *
     * @discussion Subclasses may override this method to be notified when they should begin to fetch data. Fetching
     * should be done asynchronously. The node is also responsible for managing the memory of any data.
     * The data may be remote and accessed via the network, but could also be a local database query.
     */
    override func fetchData() {
        super.fetchData()
        //        print("fetchData()")
        // use ASNetworkImageNode to get an image perhaps
        
    }
    
    /**
     * Provides an opportunity to clear any fetched data (e.g. remote / network or database-queried) on the current node.
     *
     * @discussion This will not clear data recursively for all subnodes. Either call -recursivelyClearFetchedData or
     * selectively clear fetched data.
     */
    override func clearFetchedData() {
        super.clearFetchedData()
        //        print("clearFetchedData()")
    }
    
}