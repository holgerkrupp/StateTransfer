//
//  HTTPMethod.swift
//  StateTransfer
//
//  Created by Holger Krupp on 24.02.25.
//


enum HTTPMethod: String, CaseIterable, Codable {
    case get
    case post
    case put
    case head
    case delete
    case patch
    case options
    case connect
    case trace
    
    var description: String { rawValue.uppercased() }
}