//
//  ViewController.swift
//  SwiftOverpassDemo
//
//  Created by Sho Kamei on 2017/12/03.
//  Copyright © 2017年 Sho Kamei. All rights reserved.
//

import UIKit
import SwiftOverpass

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let query = WayQuery()
        let around = Around(lat: 49.202502, lon: 16.607205, radius: 1500)
        query.around = around
        query.hasTag("waterway", equals: "stream")

        let node = NodeQuery()
        node.around = around
        node.hasTag("amenity", equals: "drinking_water")

        let wayNodeQuery = WayNodeQuery(wayQuery: query, nodeQuery: node)

        SwiftOverpass.api(endpoint: "http://overpass-api.de/api/interpreter", recurseType: "down").fetch(wayNodeQuery, elementType: .wayNode) { (response, error) in
            switch (response, error) {
            case let (.some(overpassResponse), nil):
                self.generateNamedLocations(overpassResponse: overpassResponse)
            case (nil, _):
                print("error")
                break
            default:
                print("default")
                break
            }
        }

    }

    private func generateNamedLocations(overpassResponse: OverpassResponse) {
        if let nodes = overpassResponse.nodes {
            print(nodes)
        } else if let ways = overpassResponse.ways {
            print(ways)
        } else if let relations = overpassResponse.relations {
            print(relations)
        }
    }

    override func loadView() {
        super.loadView()
    }
}

