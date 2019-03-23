/*
 * FirmwareVariables.swift
 * Copyright © 2018-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import BootoptionSupport

extension FirmwareVariables {        
        func getBootOrder() -> [BootNumber] {
                var bootOrder = [BootNumber]()
                guard var data = dataValue(forGlobalVariable: "BootOrder") else {
                        Debug.log("BootOrder NVRAM variable not found", type: .warning)
                        return bootOrder
                }
                while !data.isEmpty {
                        bootOrder.append(data.remove16())
                }
                Debug.log("%@", type: .info, argsList: bootOrder.map { $0.variableName })
                return bootOrder
        }
        
        func setBootOrder(adding bootNumber: BootNumber, atIndex index: Int = 0) throws {
                guard loadOptionData(bootNumber) != nil else {
                        Debug.log("Couldn't get %@ data, cancelling add to boot order", type: .error, argsList: bootNumber.variableName)
                        return
                }
                var bootOrder = getBootOrder()
                if bootOrder.contains(bootNumber) {
                        Debug.log("BootOrder already contains %@, cancelling add to boot order", type: .warning, argsList: bootNumber.variableName)
                        return
                }
                if bootOrder.indices.contains(index) {
                        bootOrder.insert(bootNumber, at: index)
                } else {
                        bootOrder.append(bootNumber)
                }
                try setBootOrder(array: bootOrder)
        }
        
        func setBootOrder(removing bootNumber: BootNumber) throws {
                var bootOrder = getBootOrder()
                while bootOrder.firstIndex(of: bootNumber) != nil {
                        guard let index = bootOrder.firstIndex(of: bootNumber) else {
                                break
                        }
                        bootOrder.remove(at: index)
                }
                try setBootOrder(array: bootOrder)
        }

        func setBootOrder(array: [BootNumber]) throws {
                var data = Data()
                for bootNumber in array {
                        data.append(bootNumber.toData())
                }
                try setValue(forGlobalVariable: "BootOrder", value: data)
                Debug.log("BootOrder NVRAM variable was set", type: .info)
        }
}

extension String {
        func toBootNumber() throws -> BootNumber? {
                var string = self.uppercased()
                string = string.replacingOccurrences(of: "0X", with: "")
                string = string.replacingOccurrences(of: "BOOT", with: "")
                guard Set("ABCDEF1234567890").isSuperset(of: string) else {
                        Debug.log("invalid boot number %@ (code 1)", type: .error, argsList: self)
                        return nil
                }
                guard string.count <= 4 else {
                        Debug.log("invalid boot number %@ (code 2)", type: .error, argsList: self)
                        return nil
                }
                let scanner = Scanner(string: string)
                var scanned: UInt32 = 0
                if !scanner.scanHexInt32(&scanned) {
                        Debug.log("invalid boot number %@ (code 3)", type: .error, argsList: self)
                        return nil
                }
                let number = BootNumber(scanned)
                if FirmwareVariables.default.loadOptionData(number) == nil  {
                        Debug.log("invalid boot number %@ (code 4)", type: .error, argsList: self)
                        throw FirmwareVariablesError.notFound(variable: number.variableName)
                }
                Debug.log("0x%@", type: .info, argsList: String(format: "%04X", number))
                return BootNumber(number)
        }
}
