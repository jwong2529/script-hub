//
//  TerminalCommands.swift
//  script-hub
//
//  Created by Janice Wong on 1/9/26.
//

import SwiftUI

struct TerminalActions: Equatable {
    var start: () -> Void
    var stop: () -> Void
    var clear: () -> Void
    var openSettings: () -> Void
    var isRunning: Bool
    var isLogEmpty: Bool
    
    static func == (lhs: TerminalActions, rhs: TerminalActions) -> Bool {
        return lhs.isRunning == rhs.isRunning &&
               lhs.isLogEmpty == rhs.isLogEmpty
    }
}

struct TerminalActionsKey: FocusedValueKey {
    typealias Value = TerminalActions
}

extension FocusedValues {
    var terminalActions: TerminalActions? {
        get { self[TerminalActionsKey.self] }
        set { self[TerminalActionsKey.self] = newValue }
    }
}
