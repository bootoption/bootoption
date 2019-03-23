/*
 * info.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import Gaps
import BootoptionSupport

let info = Command("info", helpMessage: "show an option's properties") {
        let invocationMessage = "<Boot####> [-v]"
        
        let parser = OptionParser(Options.verbose, helpName: "info", invocation: invocationMessage, parserOptions: [.allowUnparsedOptions])
        
        Options.verbose.helpMessage = "also show a device path list"
        
        try parser.parse(fromIndex: 2)
        
        var verbose = Options.verbose.value
        
        guard let firstArgument = parser.unparsedArguments.first else {
                throw BootoptionError.usage(errorMessage: "", usageMessage: parser.usage())
        }
        
        var o: LoadOption?
        
        switch firstArgument {
        case "-":
                /* initialize load option from standard input */
                
                verbose = true
                let fileHandle = FileHandle.init(fileDescriptor: FileHandle.standardInput.fileDescriptor, closeOnDealloc: true)
                let standardInput = fileHandle.readDataToEndOfFile()
                
                if let string = String(data: standardInput, encoding: String.Encoding.utf8) {
                        
                        guard let infoData = Data(hexString: string.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                                let errorMessage = "data initialization failed"
                                throw BootoptionError.internal(message: errorMessage, Location())
                        }
                        guard let optionFromString = try LoadOption(fromData: infoData, details: true) else {
                                let errorMessage = "load option initialization failed"
                                throw BootoptionError.internal(message: errorMessage, Location())
                        }
                        
                        o = optionFromString
                        
                } else if let optionFromData = try LoadOption(fromData: standardInput, details: true) {
                        
                        o = optionFromData
                        
                }
                
                guard o != nil else {
                        let errorMessage = "failed to initialize option from standard input"
                        throw BootoptionError.file(message: errorMessage)
                }
        default:
                /* initialize load option from bootnumber argument */
                
                for argument in parser.unparsedArguments {
                        guard let number = try argument.toBootNumber() else {
                                continue
                        }
                        guard let optionFromBootNumber = try LoadOption(fromBootNumber: number, details: true) else {
                                continue
                        }
                        
                        o = optionFromBootNumber
                        
                        break
                }
        }
        
        guard let option = o else {
                throw BootoptionError.usage(errorMessage: "", usageMessage: parser.usage())
        }
        
        var info = Info()
        
        var optionAttributes = [String]()
        
        let name = option.bootNumber.variableName
        
        info.add(title: "Name", value: name)
        
        if option.description.isEmpty {
                Debug.log("Option's description is empty", type: .warning)
        }
        
        info.add(title: "Description", value: option.description)
        
        if !option.active {
                optionAttributes.append("Disabled")
        }
        
        if option.hidden {
                optionAttributes.append("Hidden")
        }
        
        if !optionAttributes.isEmpty {
                let value = optionAttributes.joined(separator: ", ")
                info.add(title: "Attributes", value: value)
        }
        
        if verbose, let devicePathList = option.devicePathList {
                let value = devicePathList.descriptions.joined(separator: ", ")
                info.add(title: "Device Path List", value: value)
        }
        
        let volumeUUID: String? = option.devicePathList?.appleAPFSVolumeUUIDString
        
        if let partitionUUID = option.devicePathList?.partitionUUIDString {
                let title = volumeUUID == nil ? "Partition UUID" : "Container Partition UUID"
                info.add(title: title, value: partitionUUID)
        }
        
        if let volumeUUID = volumeUUID {
                info.add(title: "APFS Volume UUID", value: volumeUUID)
        }
        
        if let mbr = option.devicePathList?.masterBootPartitionNumberSignature {
                info.add(title: "MBR Signature", value: mbr.1)
                info.add(title: "Partition Number", value: mbr.0)
        }
        
        if let filePath = option.devicePathList?.filePath {
                info.add(title: "Loader Path", value: filePath)
        }
        
        if let macAddress = option.devicePathList?.macAddress {
                info.add(title: "MAC Address", value: macAddress)
        }
        
        if let arguments = option.optionalData.string, !arguments.isEmpty {
                info.add(title: "Arguments", value: arguments)
        } else if var dataView = option.optionalData.hexViewer.string {
                let title = "Data"
                /* Insert spaces to align subsequent lines with first line content */
                dataView = dataView.replacingOccurrences(of: "\n", with: "\n" + String(repeating: " ", count: title.count + 2))
                info.add(title: "Data", value: dataView)
        }
        
        info.print()
}

fileprivate struct Info {
        var properties = [Property]()
        
        mutating func add(title: String, value: String) {
                properties.append(Property(title: title, value: value))
        }
        
        func print() {
                properties.forEach {
                        Swift.print("\($0.title): \($0.value)")
                }
        }
}

fileprivate struct Property {
        let title: String
        let value: String
}
