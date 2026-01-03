//
//  AnsiText.swift
//  script-hub
//
//  Created by Janice Wong on 1/2/26.
//

import SwiftUI

struct AnsiText: View {
    let text: String
    let fontSize: Double
    
    var body: some View {
        Text(parseAnsiToAttributedString(text))
            .textSelection(.enabled)
    }
    
    private func parseAnsiToAttributedString(_ input: String) -> AttributedString {
        var finalString = AttributedString("")
        
        let standardFont = Font.system(size: fontSize, weight: .regular, design: .monospaced)
        let boldFont = Font.system(size: fontSize, weight: .bold, design: .monospaced)
        
        var currentContainer = AttributeContainer()
        currentContainer.font = standardFont
        currentContainer.foregroundColor = .primary
        
        let segments = input.components(separatedBy: "\u{001B}[")
        
        for (index, segment) in segments.enumerated() {
            if index == 0 {
                var firstChunk = AttributedString(segment)
                firstChunk.mergeAttributes(currentContainer)
                finalString.append(firstChunk)
                continue
            }
            
            if let mIndex = segment.firstIndex(of: "m") {
                let codeString = String(segment[..<mIndex])
                let content = String(segment[segment.index(after: mIndex)...])
                
                // Specific codes: 94(Blue), 92(Green), 93(Yellow), 91(Red), 90(Gray)
                
                switch codeString {
                case "0": // RESET
                    currentContainer = AttributeContainer()
                    currentContainer.foregroundColor = .primary
                    currentContainer.font = standardFont // Reset to custom size
                    
                case "1": // BOLD
                    currentContainer.font = boldFont
                    
                case "31", "91": // RED
                    currentContainer.foregroundColor = .red
                case "32", "92": // GREEN
                    currentContainer.foregroundColor = .green
                case "33", "93": // YELLOW
                    currentContainer.foregroundColor = .yellow
                case "34", "94": // BLUE
                    currentContainer.foregroundColor = .blue
                case "30", "90": // GRAY
                    currentContainer.foregroundColor = .gray
                case "39": // Default FG
                    currentContainer.foregroundColor = .primary
                    
                default:
                    break // Ignore unknown codes
                }
                
                var styledSub = AttributedString(content)
                styledSub.mergeAttributes(currentContainer)
                finalString.append(styledSub)
                
            } else {
                // If parsing failed, just append with current attributes
                var rawChunk = AttributedString(segment)
                rawChunk.mergeAttributes(currentContainer)
                finalString.append(rawChunk)
            }
        }
        
        return finalString
    }
}
