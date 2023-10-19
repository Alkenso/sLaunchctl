//  MIT License
//
//  Copyright (c) 2022 Alkenso (Vladimir Vashurkin)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import SpellbookFoundation

internal struct OutputParser {
    let string: String
    
    func value(pattern: String, options: NSRegularExpression.Options = [], groupIdx: Int) throws -> String {
        let values = try values(pattern: pattern, options: options, groupIdx: groupIdx)
        guard let first = values.first else {
            throw CommonError.notFound(what: "pattern", value: pattern, where: self)
        }
        return first
    }
    
    func values(pattern: String, options: NSRegularExpression.Options = [], groupIdx: Int) throws -> [String] {
        let regex = try NSRegularExpression(pattern: pattern, options: options)
        let searchRange = NSRange(string.startIndex..<string.endIndex, in: string)
        let values = try regex.matches(in: string, range: searchRange)
            .map { result in
                guard groupIdx <= result.numberOfRanges,
                        let matchRange = Range(result.range(at: groupIdx), in: string)
                else {
                    throw CommonError.notFound(what: "pattern group at index \(groupIdx)", value: pattern, where: self)
                }
                let value = String(string[matchRange])
                return value
            }
        return values
    }
    
    func string(forKey key: String) throws -> String {
        try value(pattern: "\(key) = (.*)", groupIdx: 1)
    }
    
    func stringArray(forKey key: String) throws -> [String] {
        let container = try container(forKey: key)
        let lines = try container
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .map { try OutputParser(string: $0).value(pattern: "\\s*(.*)", groupIdx: 1) }
        return lines
    }
    
    func stringDictionary(forKey key: String, separator: String = " => ") throws -> [String: String] {
        let lines = try stringArray(forKey: key)
        return try lines
            .map { try $0.parseKeyValuePair(separator: separator, allowSeparatorsInValue: true) }
            .reduce(into: [:]) { $0[$1.key] = $1.value }
    }
    
    func container(forKey key: String) throws -> String {
        try containers(key: key)[key].get(CommonError.notFound(what: "container", value: key, where: self))
    }
    
    func containers(key: String? = nil) throws -> [String: String] {
        let key = key ?? ".*?"
        let pattern = "^([ \t]*)\"?(\(key))\"? = \\{\n?([\\S\\s]*?)\n?^\\1\\}"
        let regex = try NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
        let searchRange = NSRange(string.startIndex..<string.endIndex, in: string)
        let values = try regex.matches(in: string, range: searchRange)
            .reduce(into: [String: String]()) { results, match in
                guard match.numberOfRanges == 4,
                      let keyRange = Range(match.range(at: 2), in: string),
                      let valueRange = Range(match.range(at: 3), in: string)
                else {
                    throw CommonError.notFound(what: "keyed container", value: pattern, where: self)
                }
                let key = String(string[keyRange])
                let value = String(string[valueRange])
                results[key] = value
            }
        return values
    }
}
