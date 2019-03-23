/*
 * create.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import Gaps
import BootoptionSupport

let create = Command("create", helpMessage: "create a new load option and add it to the boot order") {
        let invocationMessage = "-l PATH -d LABEL [-a STRING [-u] | -@ FILE] [-t FILE]"
        
        Options.loaderPath.isRequired = true
        Options.description.isRequired = true
        
        let parser = OptionParser(Options.loaderPath, Options.description, Options.optionalDataString, Options.useUCS2, Options.optionalDataFile, Options.outputToFile, helpName: "create", invocation: invocationMessage)
        
        try parser.parse(fromIndex: 2)
        
        if Options.useUCS2.wasSet && !Options.optionalDataString.wasSet {
                let errorMessage = String(format: "%@: %@ is invalid without %@", parser.helpName ?? "", Options.useUCS2.description, Options.optionalDataString.description)
                throw BootoptionError.usage(errorMessage: errorMessage, usageMessage: parser.usage())
        }
        
        if Options.optionalDataString.wasSet && Options.optionalDataFile.wasSet {
                let errorMessage = String(format: "%@: %@ and %@ cannot be used at the same time", parser.helpName ?? "", Options.optionalDataString.description, Options.optionalDataFile.description)
                throw BootoptionError.usage(errorMessage: errorMessage, usageMessage: parser.usage())
        }
        
        guard let description = Options.description.value else {
                throw BootoptionError.foundNil(id: "description", Location())
        }
        
        guard let loaderPath = Options.loaderPath.value else {
                throw BootoptionError.foundNil(id: "loaderPath", Location())
        }
        
        guard !description.isEmpty else {
                let errorMessage = "description should not be empty"
                throw BootoptionError.internal(message: errorMessage, Location())
        }
       
        var optionalData: Any? = nil
        
        if let string = Options.optionalDataString.value {
                optionalData = string as Any
        } else if Options.optionalDataFile.wasSet {
                optionalData = try Options.optionalDataFile.data() as Any
        }        
        
        if Options.outputToFile.value == nil {
                guard NSUserName() == "root" else {
                        throw BootoptionError.mustBeRoot
                }
        }
        
        let option = try LoadOption(loaderPath: loaderPath, description: description, optionalData: optionalData, useUCS2: Options.useUCS2.value)
        
        switch Options.outputToFile.wasSet {
        case true:
                let outputFileHandle = try Options.outputToFile.fileHandle()
                outputFileHandle.write(try option.data())
                outputFileHandle.closeFile()
        case false:
                guard let newBootNumber = try setNewLoadOption(data: try option.data(), addingToBootOrder: true) else {
                        throw BootoptionError.foundNil(id: "newBootNumber", Location())
                }
                Debug.log("Set a new load option with name %@", type: .info, argsList: newBootNumber.variableName)
        }
}

fileprivate func discoverUnusedBootNumber() -> BootNumber? {
        for bootNumber: BootNumber in 0x0000 ..< 0x007F {
                guard FirmwareVariables.default.loadOptionData(bootNumber) == nil else {
                        continue
                }
                Debug.log("Unused boot number discovered: %@", type: .info, argsList: bootNumber.variableName)
                return bootNumber
        }
        Debug.log("Unused boot number discovery failed", type: .error)
        return nil
}

fileprivate func setNewLoadOption(data: Data, addingToBootOrder: Bool) throws -> BootNumber? {
        guard let newBootNumber = discoverUnusedBootNumber() else {
                return nil
        }
        try FirmwareVariables.default.setValue(forGlobalVariable: newBootNumber.variableName, value: data)
        try FirmwareVariables.default.setBootOrder(adding: newBootNumber, atIndex: 0)
        return newBootNumber
}
