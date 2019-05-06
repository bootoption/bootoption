/*
 * Order.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import Gaps
import BootoptionSupport

let order = Command("order", helpMessage: "change the boot order") {
        let invocationMessage = "<current position> to <new position>"
        
        let parser = OptionParser(Options.printBootOrder, helpName: "order", invocation: invocationMessage, settings: [.allowUnparsedOptions])
        
        try parser.parse(fromIndex: 2)
        
        if !Options.printBootOrder.wasSet, parser.unparsedArguments.isEmpty {
                throw BootoptionError.usage(helpName: nil, errorMessage: nil, usageMessage: parser.usage())
        }
        
        var bootOrder = FirmwareVariables.default.getBootOrder()
        
        if Options.printBootOrder.wasSet {
                guard !bootOrder.isEmpty else {
                        print("BootOrder is currently empty")
                        exit(0)
                }
                print(bootOrder.map { $0.variableName }.joined(separator: ", "))
                exit(0)
        }
        
        guard !bootOrder.isEmpty else {
                let errorMessage = "the boot order is not set and cannot be reordered"
                throw BootoptionError.usage(helpName: nil, errorMessage: errorMessage, usageMessage: nil)
        }
        
        guard bootOrder.count != 1 else {
                let errorMessage = "the boot order contains a single option and cannot be reordered"
                throw BootoptionError.usage(helpName: nil, errorMessage: errorMessage, usageMessage: nil)
        }
        
        var intArgs = [Int]()
        
        for argument in parser.unparsedArguments {
                if let value = Int(argument) {
                        intArgs.append(value - 1)
                }
                if intArgs.count == 2 {
                        break
                }
        }
        
        guard intArgs.count == 2 else {
                throw BootoptionError.usage(helpName: nil, errorMessage: nil, usageMessage: parser.usage())
        }
        
        guard bootOrder.indices.contains(intArgs[0]) else {
                let validValues = bootOrder.indices.map { String($0 + 1) }.joined(separator: ", ")
                let errorMessage = "'from' position '\(intArgs[0] + 1)' is invalid, allowed values: \(validValues)"
                throw BootoptionError.usage(helpName: nil, errorMessage: errorMessage, usageMessage: parser.usage())
        }
        
        guard bootOrder.indices.contains(intArgs[1]) else {
                let validValues = bootOrder.indices.map { String($0 + 1) }.joined(separator: ", ")
                let errorMessage = "'to' position '\(intArgs[1] + 1)' is invalid, allowed values: \(validValues)"
                throw BootoptionError.usage(helpName: nil, errorMessage: errorMessage, usageMessage: parser.usage())
        }
        
        guard intArgs[0] != intArgs[1] else {
                let errorMessage = "lhs == rhs"
                throw BootoptionError.usage(helpName: nil, errorMessage: errorMessage, usageMessage: parser.usage())
        }
        
        guard NSUserName() == "root" else {
                throw BootoptionError.mustBeRoot
        }
        
        bootOrder.order(itemAtIndex: intArgs[0], to: intArgs[1])
        
        try FirmwareVariables.default.setBootOrder(array: bootOrder)
}
