/*
 * delete.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import Gaps
import BootoptionSupport

let delete = Command("delete", helpMessage: "unset firmware variables") {
        let invocationMessage = "[-n ####] [-x] [-t] [-o]"
        
        Options.bootNumber.helpMessage = "variable to delete, Boot####"
        
        let parser = OptionParser(Options.bootNumber, Options.deleteBootNext, Options.deleteTimeout, Options.deleteBootOrder, helpName: "delete", invocation: invocationMessage)
        
        try parser.parse(fromIndex: 2)
        
        guard NSUserName() == "root" else {
                throw BootoptionError.mustBeRoot
        }
        
        var didSomething = false
        
        if let bootNumber: BootNumber = Options.bootNumber.value {
                /* Delete specified option */
                didSomething = true
                
                if FirmwareVariables.default.getBootOrder().contains(bootNumber) {
                        Debug.log("Variable to delete is present in BootOrder", type: .info)
                        
                        try FirmwareVariables.default.setBootOrder(removing: bootNumber)                        
                }
                
                Debug.log("Deleting variable", type: .info)
                
                try FirmwareVariables.default.delete(globalVariable: bootNumber.variableName)
        }
        
        if Options.deleteBootNext.wasSet {
                /* Delete boot next */
                didSomething = true
                try FirmwareVariables.default.delete(globalVariable: "BootNext")
        }
        
        if Options.deleteTimeout.wasSet {
                /* Delete timeout */
                didSomething = true
                try FirmwareVariables.default.delete(globalVariable: "Timeout")
        }
        
        if Options.deleteBootOrder.wasSet {
                /* Delete boot order */
                didSomething = true
                try FirmwareVariables.default.delete(globalVariable: "BootOrder")
        }
        
        guard didSomething == true else {
                throw BootoptionError.usage(errorMessage: "", usageMessage: parser.usage())
        }
}
