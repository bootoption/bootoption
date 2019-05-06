/*
 * LoadOption+PrintInfo.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import BootoptionSupport

internal extension LoadOption {
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
        
        func printInfo(verbose: Bool) {
                var info = Info()
                
                var optionAttributes = [String]()
                
                let name = bootNumber.variableName
                
                info.add(title: "Name", value: name)
                
                if description.string.isEmpty {
                        Debug.log("Option's description is empty", type: .warning)
                }
                
                info.add(title: "Description", value: description.string)
                
                if !attributes.active {
                        optionAttributes.append("Disabled")
                }
                
                if attributes.hidden {
                        optionAttributes.append("Hidden")
                }
                
                if !optionAttributes.isEmpty {
                        let value = optionAttributes.joined(separator: ", ")
                        info.add(title: "Attributes", value: value)
                }
                
                if verbose, let devicePathList = devicePathList {
                        let value = devicePathList.descriptions.joined(separator: ", ")
                        info.add(title: "Device Path List", value: value)
                }
                
                let volumeUUID: String? = devicePathList?.appleAPFSVolumeUUIDString
                
                if let partitionUUID = devicePathList?.partitionUUIDString {
                        let title = volumeUUID == nil ? "Partition UUID" : "Container Partition UUID"
                        info.add(title: title, value: partitionUUID)
                }
                
                if let volumeUUID = volumeUUID {
                        info.add(title: "APFS Volume UUID", value: volumeUUID)
                }
                
                if let mbrSig = devicePathList?.masterBootSignature, let partNo = devicePathList?.partitionNumber {
                        info.add(title: "MBR Signature", value: mbrSig)
                        info.add(title: "Partition Number", value: partNo)
                }
                
                if let filePath = devicePathList?.filePath {
                        info.add(title: "Loader Path", value: filePath)
                }
                
                if let macAddress = devicePathList?.macAddress {
                        info.add(title: "MAC Address", value: macAddress)
                }
                
                if let arguments = optionalData?.string, !arguments.isEmpty {
                        info.add(title: "Arguments", value: arguments)
                } else if var dataView = optionalData?.hexViewer.string {
                        let title = "Data"
                        /* Insert spaces to align subsequent lines with first line content */
                        dataView = dataView.replacingOccurrences(of: "\n", with: "\n" + String(repeating: " ", count: title.count + 2))
                        info.add(title: "Data", value: dataView)
                }
                
                info.print()
        }
}
