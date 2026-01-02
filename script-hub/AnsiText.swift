//
//  AnsiText.swift
//  script-hub
//
//  Created by Janice Wong on 1/2/26.
//

import SwiftUI

struct AnsiText: View {
    let text: String
    
    var body: some View {
        Text(parseAnsiToAttributedString(text))
            .textSelection(.enabled)
    }
    
    private func parseAnsiToAttributedString(_ input: String) -> AttributedString {
        var finalString = AttributedString("")
        var currentContainer = AttributeContainer()
        
        let segments = input.components(separatedBy: "\u{001B}[")
        
        for (index, segment) in segments.enumerated() {
            if index == 0 {
                finalString.append(AttributedString(segment))
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
                case "1": // BOLD
                    currentContainer.font = .system(.body, design: .monospaced).bold()
                    
                case "91": // FG_RED
                    currentContainer.foregroundColor = .red
                case "92": // FG_GREEN
                    currentContainer.foregroundColor = .green
                case "93": // FG_YELLOW
                    currentContainer.foregroundColor = .yellow
                case "94": // FG_BLUE
                    currentContainer.foregroundColor = .blue
                case "90": // FG_GRAY
                    currentContainer.foregroundColor = .gray
                    
                default:
                    break // Ignore unknown codes
                }
                
                var styledSub = AttributedString(content)
                styledSub.mergeAttributes(currentContainer)
                finalString.append(styledSub)
                
            } else {
                finalString.append(AttributedString(segment))
            }
        }
        
        return finalString
    }
}
