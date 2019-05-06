/*
 * Info.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import Gaps
import BootoptionSupport

let info = Command("info", helpMessage: "show an option's properties") {
        let invocationMessage = "<Boot####> [-v]"
        
        let parser = OptionParser(Options.verbose, helpName: "info", invocation: invocationMessage, settings: [.allowUnparsedOptions])
        
        Options.verbose.helpMessage = "also show a device path list"
        
        try parser.parse(fromIndex: 2)
        
        var verbose = Options.verbose.boolValue
        
        guard let argument = parser.unparsedArguments.first else {
                throw BootoptionError.usage(helpName: nil, errorMessage: nil, usageMessage: parser.usage())
        }
        
        var option: LoadOption
        
        switch argument {
        case "-":
                /* initialize load option from standard input */
                verbose = true
                let fileHandle = FileHandle.init(fileDescriptor: FileHandle.standardInput.fileDescriptor, closeOnDealloc: true)
                Debug.log("Reading option data from standard input", type: .info)
                let standardInput = fileHandle.readDataToEndOfFile()
                
                let string = String(data: standardInput, encoding: String.Encoding.utf8)
                
                switch string {
                case .some:
                        guard let data = Data(hexString: string!.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                                throw BootoptionError.internal(errorMessage: "data initialization failed", file: #file, function: #function)
                        }
                        
                        option = try LoadOption(fromData: data, details: true)
                case .none:
                        option = try LoadOption(fromData: standardInput, details: true)
                }
        default:
                /* initialize load option from bootnumber argument */
                option = try LoadOption(fromBootNumber: try BootNumber(variableName: argument), details: true)
        }
        
        option.printInfo(verbose: verbose)
}
