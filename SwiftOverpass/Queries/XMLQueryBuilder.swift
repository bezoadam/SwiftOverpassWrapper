//
//  XMLQueryBuilder.swift
//  SwiftOverpass
//
//  Created by Sho Kamei on 6/26/18.
//  Copyright © 2018 Sho Kamei. All rights reserved.
//

import Foundation
import AEXML

public final class XMLQueryBuilder: QueryBuilder {
    let queries: [OverpassQuery]
    let verbosity: OverpassApi.OutputVerbosity?
    let order: OverpassApi.OutputOrder?
    let timeout: Int?
    let elementLimit: Int?
    let recurseType: String?
    
    init(queries: [OverpassQuery], verbosity: OverpassApi.OutputVerbosity?, order: OverpassApi.OutputOrder?, timeout: Int?, elementLimit: Int?, recurseType: String?) {
        self.queries = queries
        self.verbosity = verbosity
        self.order = order
        self.timeout = timeout
        self.elementLimit = elementLimit
        self.recurseType = recurseType
    }
    
    public func makeQuery() -> String {
        let doc = AEXMLDocument()
        
        // Sets attributes to <osm-script> element
        var osmAttributes = [String : String]()
        if let timeout = timeout {
            osmAttributes["timeout"] = "\(timeout)"
        }
        if let elementLimit = elementLimit {
            osmAttributes["element-limit"] = "\(elementLimit)"
        }
        var osmScript = doc.addChild(name: "osm-script", attributes: osmAttributes)
        
        // Adds <query> elements to main document
        queries.forEach {
            if let parent = $0.parent {
                // If the query has a parent query, add <recurse> element to the query
                osmScript = recurse(parent, osmScript)
                
                let union = osmScript.addChild(name: "union")
                union.addChild(name: "item")
                union.addChild(makeRecurseElement($0, parent: parent))
            } else {
                // Otherwise add <query> element to the query
                let union = osmScript.addChild(name: "union")
                union.addChild(name: "item")
                union.addChild(makeQueryElement($0))
            }
        }
        
        // Finally, put <print> element to make output
        var printAttributes = [String : String]()
        if let verbosity = verbosity {
            printAttributes["mode"] = verbosity.stringValue
        }
        if let order = order, order == .qt {
            printAttributes["order"] = order.stringValue
        }
        if let recurseType = recurseType {
            osmScript.addChild(makeUnionElement(recurseType: recurseType))
        }
        osmScript.addChild(name: "print", attributes: printAttributes)
        
        return doc.xmlCompact
    }

    public func makeWayNodeQuery() -> String {
        let doc = AEXMLDocument()
        // Sets attributes to <osm-script> element
        var osmAttributes = [String : String]()
        if let timeout = timeout {
            osmAttributes["timeout"] = "\(timeout)"
        }
        if let elementLimit = elementLimit {
            osmAttributes["element-limit"] = "\(elementLimit)"
        }
        let osmScript = doc.addChild(name: "osm-script", attributes: osmAttributes)
        let union = osmScript.addChild(name: "union")
        // Adds <query> elements to main document
        queries.forEach { wayNodeQuery in
            if let wayNodeQuery = wayNodeQuery as? WayNodeQuery {
                wayNodeQuery.wayQueries.forEach { union.addChild(makeQueryElement($0)) }
                wayNodeQuery.nodeQueries.forEach { union.addChild(makeQueryElement($0)) }
            }
        }
        // Finally, put <print> element to make output
        var printAttributes = [String : String]()
        if let verbosity = verbosity {
            printAttributes["mode"] = verbosity.stringValue
        }
        if let order = order, order == .qt {
            printAttributes["order"] = order.stringValue
        }
        union.addChild(name: "recurse", value: nil, attributes: ["type": "way-node"])
        osmScript.addChild(name: "print", attributes: printAttributes)
        return doc.xmlCompact
    }

    private func makeUnionElement(recurseType: String) -> AEXMLElement {
        let element = AEXMLElement(name: "union")
        element.addChild(name: "item")
        element.addChild(name: "recurse", attributes: ["type": recurseType])
        return element
    }
    
    private func makeQueryElement(_ query: OverpassQuery) -> AEXMLElement {
        let element = AEXMLElement(name: "query", attributes: ["type": query.type.rawValue])
        
        // Add <has-kv> elements to <query> element as children
        element.addChildren(query.tags.map { makeHasKvElement($0.value) })
        
        // Add <bbox-query> element to <query> element as child
        if let bbox = query.boundingBox {
            element.addChild(makeBboxQueryElement(bbox))
        }

        // Add <around> element to <query> element as child
        if let around = query.around {
            element.addChild(makeAroundElement(around))
        }

        return element
    }
    
    private func recurse(_ query: OverpassQuery, _ element: AEXMLElement) -> AEXMLElement {
        var element = element
        
        if let parent = query.parent {
            element = recurse(parent, element)
            element.addChild(makeRecurseElement(query, parent: parent))
        } else {
            element.addChild(makeQueryElement(query))
        }
        
        return element
    }
    
    private func makeRecurseElement(_ query: OverpassQuery, parent: OverpassQuery) -> AEXMLElement {
        let relationType = "\(parent.type.rawValue)-\(query.type.rawValue)"
        return AEXMLElement(name: "recurse", attributes: ["type" : relationType])
    }
    
    /**
     Makes a <has-kv> element
     */
    private func makeHasKvElement(_ tag: OverpassTag) -> AEXMLElement {
        let aValue = tag.value ?? ""
        var attributes = ["k" : tag.key]
        
        if tag.isNegation {
            attributes["modv"] = "not"
        }
        
        if tag.isRegex {
            attributes["regv"] = aValue
        } else {
            attributes["v"] = aValue
        }
        
        return AEXMLElement(name: "has-kv", attributes: attributes)
    }
    
    private func makeBboxQueryElement(_ bbox: BoudingBox) -> AEXMLElement {
        return AEXMLElement(name: "bbox-query", attributes: ["s" : "\(bbox.s)", "n" : "\(bbox.n)", "w" : "\(bbox.w)", "e" : "\(bbox.e)"])
    }

    private func makeAroundElement(_ around: Around) -> AEXMLElement {
        return AEXMLElement(name: "around", attributes: ["lat": "\(around.lat)", "lon": "\(around.lon)", "radius": "\(around.radius)"])
    }
}
