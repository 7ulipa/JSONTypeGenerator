//
//  main.swift
//  JSONTypeGenerator
//
//  Created by DirGoTii on 03/01/2017.
//  Copyright © 2017 Tulipa. All rights reserved.
//

import Foundation

import Foundation

extension String {
    func substring(with range: NSRange) -> String {
        return self.substring(with: Range<String.Index>(uncheckedBounds: (self.characters.index(self.characters.startIndex, offsetBy: range.location), self.characters.index(self.characters.startIndex, offsetBy: range.length + range.location))))
    }
}

let params = CommandLine.arguments.suffix(from: 1).reduce(([:], nil)) { (acc: ([String: String], String?), value) -> ([String: String], String?) in
    if let key = acc.1 {
        var result = acc.0
        result[key] = value
        return (result, nil)
    } else {
        return (acc.0, value)
    }
    }.0

guard let path = params["-i"] else {
    fatalError("invalid parameters")
}

guard let outputModlesPath = params["-om"] else {
    fatalError("invalid parameters")
}

guard let outputExtensionsPath = params["-oe"] else {
    fatalError("invalid parameters")
}

guard let input = try? String(contentsOfFile: path) else {
    fatalError("invalid input:\(path)")
}

guard let bagExpress = try? NSRegularExpression(pattern: "(struct|class)\\s*?\\w+\\s*?\\{.*?\\}", options: [.dotMatchesLineSeparators]) else {
    fatalError("regular expression error!!!")
}

guard let typeExpress = try? NSRegularExpression(pattern: "(struct|class)(?=.*?\\{)", options: [.dotMatchesLineSeparators]) else {
    fatalError("regular expression error!!!")
}

guard let nameExpress = try? NSRegularExpression(pattern: "(?<=struct|class).*?(?=\\{)", options: []) else {
    fatalError("regular expression error!!!")
}

guard let propertyExpress = try? NSRegularExpression(pattern: "(let|var)\\s*?\\w+\\s*?:\\s*?\\w+(\\s*?<\\s*?\\w+?)?", options: []) else {
    fatalError("regular expression error!!!")
}

var modelString = ""
var extensionString = ""

bagExpress.enumerateMatches(in: input, options: [], range: NSRange(location: 0, length: input.characters.count)) { (result, _, _) in
    if let range = result?.range {
        let bag = input.substring(with: range)
        var type: String?
        typeExpress.enumerateMatches(in: bag, options: [], range: NSRange(location: 0, length: bag.characters.count), using: { (typeResult, _, _) in
            if let bagRange = typeResult?.range {
                type = bag.substring(with: bagRange)
            }
        })
        
        guard let bagType = type?.trimmingCharacters(in: .whitespaces) else {
            fatalError("type find error!!!")
        }
        
        var name: String?
        nameExpress.enumerateMatches(in: bag, options: [], range: NSRange(location: 0, length: bag.characters.count), using: { (nameResult, _, _) in
            if let range = nameResult?.range {
                name = bag.substring(with: range)
            }
        })
        
        guard let bagName = name?.trimmingCharacters(in: .whitespaces) else {
            fatalError("name find error!!!")
        }
        
        modelString.append("\(bagType) \(bagName) {\n")
        extensionString.append("extenstion \(bagName): JSONType {\n")
        
        propertyExpress.enumerateMatches(in: bag, options: [], range: NSRange(location: 0, length: bag.characters.count), using: { (propertyResult, _, _) in
            if let range = propertyResult?.range {
                let propertyLine = bag.substring(with: range)
                let propertyContract = (propertyLine.components(separatedBy: " ").first?.trimmingCharacters(in: .whitespaces) ?? "").trimmingCharacters(in: .whitespaces)
                let propertyName = (propertyLine.components(separatedBy: " ")[1].components(separatedBy: ":").first?.trimmingCharacters(in: .whitespaces) ?? "").trimmingCharacters(in: .whitespaces)
                let lastPropertyBag = propertyLine.components(separatedBy: ":").last?.components(separatedBy: "<")
                let propertyType = (lastPropertyBag?.first ?? "").trimmingCharacters(in: .whitespaces)
                let jsonKey = lastPropertyBag?.count == 2 ? (lastPropertyBag?.last ?? "").trimmingCharacters(in: .whitespaces) : propertyName
                
                modelString.append("\t\(propertyContract) \(propertyName): \(propertyType)?\n")
            }
        })
        
        modelString.append("}\n\n")
        extensionString.append("}\n\n")
    }
}


try modelString.write(toFile: outputModlesPath, atomically: true, encoding: .utf8)

try extensionString.write(toFile: outputExtensionsPath, atomically: true, encoding: .utf8)
