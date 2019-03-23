/*
 * set.swift
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
                let errorMessage = String(format: "%@: %@ is invalid without %@", parser.helpName ?? "", Options.useUCS2.description, Options.optionalDataString.description)
                throw BootoptionError.usage(errorMessage: errorMessage, usageMessage: parser.usage())
        }
        
        if Options.optionalDataString.wasSet && Options.optionalDataFile.wasSet {
                let errorMessage = String(format: "%@: %@ and %@ cannot be used at the same time", parser.helpName ?? "", Options.optionalDataString.description, Options.optionalDataFile.description)
                throw BootoptionError.usage(errorMessage: errorMessage, usageMessage: parser.usage())
        }
        
        if Options.bootNumber.wasSet {
                guard Options.description.wasSet || Options.optionalDataString.wasSet || Options.optionalDataFile.wasSet || Options.active.wasSet || Options.hidden.wasSet else {
                        let errorMessage = String(format: "%@ used without required accompanying options", Options.bootNumber.description)
                        throw BootoptionError.usage(errorMessage: errorMessage, usageMessage: parser.usage())
                }
        }
        
        if Options.description.wasSet || Options.optionalDataString.wasSet || Options.optionalDataFile.wasSet || Options.active.wasSet || Options.hidden.wasSet {
                Options.bootNumber.isRequired = true
                try parser.parse(fromIndex: 2)
        }
        
        if let description = Options.description.value {
                guard !description.isEmpty else {
                        let errorMessage = "description should not be empty"
                        throw BootoptionError.internal(message: errorMessage, Location())
                }
        }
        
        guard NSUserName() == "root" else {
                throw BootoptionError.mustBeRoot
        }
        
        /* Load option */
        
        if let bootNumber = Options.bootNumber.value {
                
                guard var option = try LoadOption(fromBootNumber: bootNumber, details: true) else {
                        let errorMessage = String(format: "failed to initialize load option named %@", bootNumber.variableName)
                        throw BootoptionError.internal(message: errorMessage, Location())
                }
                
                /* Description */
                
                if let description = Options.description.value, !description.isEmpty {
                        option.description = description
                        optionWantsUpdating = true
                }
                
                /* Optional data */
                
                if Options.optionalDataString.wasSet {
                        if Options.optionalDataString.value == nil {
                                optionalDataWantsRemoving = true
                        } else if Options.optionalDataString.value!.isEmpty {
                                optionalDataWantsRemoving = true
                        } else {
                                try option.optionalData.set(string: Options.optionalDataString.value!, isClover: option.isClover, useUCS2: Options.useUCS2.value)
                                optionWantsUpdating = true
                        }
                }
                
                if Options.optionalDataFile.wasSet {
                        let data = try Options.optionalDataFile.data()
                        option.optionalData.data = data
                        optionWantsUpdating = true
                }
                
                if optionalDataWantsRemoving == true {
                        if option.optionalData.data != nil {
                                Debug.log("Removing optional data", type: .info)
                                option.optionalData.remove()
                                optionWantsUpdating = true
                        } else {
                                Debug.log("Optional data is already nil", type: .info)
                                didSomething = true
                        }
                }
                
                /* Attributes */
                
                if let newHiddenValue = Options.hidden.value  {
                        option.hidden = newHiddenValue
                        optionWantsUpdating = true
                }
                
                if let newActiveValue = Options.active.value{
                        option.active = newActiveValue
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
                didSomething = true
        }
        
        guard didSomething == true else {
                throw BootoptionError.usage(errorMessage: "", usageMessage: parser.usage())
        }
}
