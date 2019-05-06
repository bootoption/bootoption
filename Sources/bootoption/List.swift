/*
 * List.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import Gaps
import BootoptionSupport

let list = Command("list", helpMessage: "show the firmware boot menu") {
        var strings = [String]()
        let bootCurrent = FirmwareVariables.default.dataValue(forGlobalVariable: "BootCurrent")?.toUInt16()
        let bootNext = FirmwareVariables.default.dataValue(forGlobalVariable: "BootNext")?.toUInt16()
        let timeout = FirmwareVariables.default.dataValue(forGlobalVariable: "Timeout")?.toUInt16()
        let bootOrder: [BootNumber] = FirmwareVariables.default.getBootOrder()
        
        if let bootCurrent = bootCurrent {
                strings.append("BootCurrent: " + bootCurrent.variableName)
        } else {
                strings.append("BootCurrent: Not set")
        }
        
        if let bootNext = bootNext {
                strings.append("BootNext: " + bootNext.variableName)
        } else {
                strings.append("BootNext: Not set")
        }
        
        if let timeout = timeout {
                strings.append("Timeout: " + String(timeout))
        } else {
                strings.append("Timeout: Not set")
        }
        
        /* List of options */
        
        var options = [LoadOption]()
        
        for bootNumber: BootNumber in 0x0 ..< 0xFF {
                guard let option = try? LoadOption(fromBootNumber: bootNumber) else {
                        continue
                }                
                options.append(option)
                #if DEBUG
                        guard let data = FirmwareVariables.default.dataValue(forGlobalVariable: bootNumber.variableName) else {
                                Debug.log("Nvram.shared.loadOptionData(%@) returned nil", type: .warning, argsList: bootNumber.variableName)
                                continue
                        }
                        Debug.log("%@ %@", type: .info, argsList: bootNumber.variableName, data)
                #endif
        }
        
        options.sort {
                if let lhs = bootOrder.firstIndex(of: $0.bootNumber), let rhs = bootOrder.firstIndex(of: $1.bootNumber) {
                        return lhs < rhs
                }
                if bootOrder.contains($0.bootNumber) {
                        return true
                }
                return false
        }
        
        for option in options {
                var string = ""
                
                /* Position in boot order */
                
                if let firstIndex = bootOrder.firstIndex(of: option.bootNumber) {
                        string += String(firstIndex + 1).leftPadding(toLength: 3, withPad: " ")
                } else {
                        string += " --"
                }
                
                string += ": "
                
                /* Boot number */
                
                string += option.bootNumber.variableName + " "
                
                /* Description */
                
                if !option.description.string.isEmpty {
                        string += option.description.string
                } else {
                        string += String(repeating: "-", count: 16)
                        Debug.log("An option's description was empty", type: .warning)
                }
                
                /* Attributes */
                
                if !option.attributes.active {
                        string += "  *D"
                }
                
                if option.attributes.hidden {
                        string += "  *H"
                }
                
                strings.append(string)
        }
        
        print(strings.joined(separator: "\n"))
}
