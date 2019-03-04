//
//  WayNodeQuery.swift
//  SwiftOverpass
//
//  Created by Adam Bezák on 04/03/2019.
//  Copyright © 2019 Sho Kamei. All rights reserved.
//

import Foundation

/**
 Class for creating way node query
 */
public final class WayNodeQuery: OverpassQuery {

    // MARK: OverpassQuery
    public var type: ElementType = .wayNode
    public var parent: OverpassQuery?
    public var tags: [String : OverpassTag] = [:]
    public var boundingBox: BoudingBox?
    public var around: Around?
    public var wayQueries: [WayQuery]
    public var nodeQueries: [NodeQuery]

    public init(wayQueries: [WayQuery], nodeQueries: [NodeQuery]) {
        self.wayQueries = wayQueries
        self.nodeQueries = nodeQueries
    }
}
