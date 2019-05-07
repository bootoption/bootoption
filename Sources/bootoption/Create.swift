/*
 * Create.swift
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
                let errorMessage = String(format: "%@ is invalid without %@", Options.useUCS2.description, Options.optionalDataString.description)
                throw BootoptionError.usage(helpName: parser.helpName, errorMessage: errorMessage, usageMessage: parser.usage())
        }
        
        if Options.optionalDataString.wasSet && Options.optionalDataFile.wasSet {
                let errorMessage = String(format: "%@ and %@ cannot be used at the same time", Options.optionalDataString.description, Options.optionalDataFile.description)
                throw BootoptionError.usage(helpName: parser.helpName, errorMessage: errorMessage, usageMessage: parser.usage())
        }
        
        guard let description = Options.description.value else {
                throw BootoptionError.foundNil(description: "description value", file: #file, function: #function)
        }
        
        guard let loaderPath = Options.loaderPath.value else {
                throw BootoptionError.foundNil(description: "loader path value", file: #file, function: #function)
        }
        
        guard !description.isEmpty else {
                let errorMessage = "description should not be empty"
                throw BootoptionError.internal(errorMessage: errorMessage, file: #file, function: #function)
        }
       
        var optionalData: Any? = nil
        
        if let string = Options.optionalDataString.value {
                optionalData = string as Any
        } else if Options.optionalDataFile.wasSet {
                optionalData = try Options.optionalDataFile.data() as Any
        }        
        
        if Options.outputToFile.value == nil, NSUserName() != "root" {
                throw BootoptionError.mustBeRoot
        }
        
        let option = try LoadOption(loaderPath: loaderPath, description: description, optionalData: optionalData, useUCS2: Options.useUCS2.boolValue)
        
        switch Options.outputToFile.wasSet {
        case true:
                let outputFileHandle = try Options.outputToFile.fileHandle()
                outputFileHandle.write(try option.data())
                outputFileHandle.closeFile()
        case false:
                let newBootNumber = try FirmwareVariables.default.setNewLoadOption(data: try option.data(), addingToBootOrder: true)
                Debug.log("Set a new load option with name %@", type: .info, argsList: newBootNumber.variableName)
        }
}
