/*
 * Set.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import Gaps
import BootoptionSupport

let set = Command("set", helpMessage: "set firmware variables") {
        let invocationMessage = "-n #### [-d LABEL] [-a STRING [-u] | -@ FILE]" + "\n" + "-x #### | -t SECONDS | -o #### [####] [...]"
        
        var optionWantsUpdating = false
        var optionalDataWantsRemoving = false
        var didSomething = false
        
        let parser = OptionParser(Options.bootNumber, Options.description, Options.optionalDataString, Options.useUCS2, Options.optionalDataFile, Options.active, Options.hidden, Options.setBootNext, Options.setTimeout, Options.setBootOrder, helpName: "set", invocation: invocationMessage)
        
        try parser.parse(fromIndex: 2)
        
        if Options.useUCS2.wasSet && !Options.optionalDataString.wasSet {
                let errorMessage = String(format: "%@ is invalid without %@", Options.useUCS2.description, Options.optionalDataString.description)
                throw BootoptionError.usage(helpName: parser.helpName, errorMessage: errorMessage, usageMessage: parser.usage())
        }
        
        if Options.optionalDataString.wasSet && Options.optionalDataFile.wasSet {
                let errorMessage = String(format: "%@ and %@ cannot be used at the same time", parser.helpName ?? "", Options.optionalDataString.description, Options.optionalDataFile.description)
                throw BootoptionError.usage(helpName: parser.helpName, errorMessage: errorMessage, usageMessage: parser.usage())
        }
        
        if Options.bootNumber.wasSet {
                guard Options.description.wasSet || Options.optionalDataString.wasSet || Options.optionalDataFile.wasSet || Options.active.wasSet || Options.hidden.wasSet else {
                        let errorMessage = String(format: "%@ used without required accompanying options", Options.bootNumber.description)
                        throw BootoptionError.usage(helpName: parser.helpName, errorMessage: errorMessage, usageMessage: parser.usage())
                }
        }
        
        if Options.description.wasSet || Options.optionalDataString.wasSet || Options.optionalDataFile.wasSet || Options.active.wasSet || Options.hidden.wasSet {
                Options.bootNumber.isRequired = true
                try parser.parse(fromIndex: 2)
        }
        
        if let description = Options.description.value {
                guard !description.isEmpty else {
                        let errorMessage = "description should not be empty"
                        throw BootoptionError.internal(errorMessage: errorMessage, file: #file, function: #function)
                }
        }
        
        guard NSUserName() == "root" else {
                throw BootoptionError.mustBeRoot
        }
        
        /* Load option */
        
        if let bootNumber = Options.bootNumber.value {
                
                var option = try LoadOption(fromBootNumber: bootNumber, details: true)
                
                /* Description */
                
                if let description = Options.description.value, !description.isEmpty {
                        option.description.string = description
                        optionWantsUpdating = true
                }
                
                /* Optional data */
                
                if Options.optionalDataString.wasSet {
                        if Options.optionalDataString.value == nil {
                                optionalDataWantsRemoving = true
                        } else if let value = Options.optionalDataString.value, value.isEmpty {
                                optionalDataWantsRemoving = true
                        } else {
                                option.optionalData = try LoadOptionOptionalData(string: Options.optionalDataString.value!, isClover: option.isClover, useUCS2: Options.useUCS2.boolValue)
                                optionWantsUpdating = true
                        }
                }
                
                if Options.optionalDataFile.wasSet {
                        option.optionalData = LoadOptionOptionalData(data: try Options.optionalDataFile.data()!)
                        optionWantsUpdating = true
                }
                
                if optionalDataWantsRemoving == true {
                        Debug.log("Removing optional data", type: .info)
                        option.optionalData = LoadOptionOptionalData()
                        optionWantsUpdating = true
                }
                
                /* Attributes */
                
                if let newHiddenValue = Options.hidden.value  {
                        option.attributes.hidden = newHiddenValue
                        optionWantsUpdating = true
                }
                
                if let newActiveValue = Options.active.value{
                        option.attributes.active = newActiveValue
                        optionWantsUpdating = true
                }
                
                /* Update option */
                
                if optionWantsUpdating == true {
                        try FirmwareVariables.default.setValue(forGlobalVariable: option.bootNumber.variableName, value: option.data())
                        Debug.log("NVRAM %@ was set", type: .info, argsList: option.bootNumber.variableName)
                        didSomething = true
                }
        }
        
        /* BootNext, Timeout, BootOrder */
        
        if let bootNextValue: BootNumber = Options.setBootNext.value {
                try FirmwareVariables.default.setValue(forGlobalVariable: "BootNext", value: bootNextValue.toData())
                Debug.log("NVRAM BootNext was set", type: .info)
                didSomething = true
        }
        
        if let timeoutValue: UInt16 = Options.setTimeout.value {
                try FirmwareVariables.default.setValue(forGlobalVariable: "Timeout", value: timeoutValue.toData())
                Debug.log("NVRAM Timeout was set", type: .info)
                didSomething = true
        }
        
        if let bootOrder: [BootNumber] = Options.setBootOrder.value {
                try FirmwareVariables.default.setBootOrder(array: bootOrder)
                Debug.log("NVRAM Timeout was set", type: .info)
                didSomething = true
        }
        
        guard didSomething == true else {
                throw BootoptionError.usage(helpName: nil, errorMessage: nil, usageMessage: parser.usage())
        }
}
