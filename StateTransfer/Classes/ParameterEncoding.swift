//
//  ParameterEncoding.swift
//  StateTransfer
//
//  Created by Holger Krupp on 24.02.25.
//


enum ParameterEncoding: String, CaseIterable, Codable {
    
    case form = "Form encoded"
    case json = "JSON encoded"
    
}