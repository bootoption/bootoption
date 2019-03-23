/*
 * reboot.swift
 * Copyright © 2018-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import Gaps
import BootoptionSupport

let reboot = Command("reboot", helpMessage: "reboot to firmware settings") {
        if NSUserName() != "root" {
                throw BootoptionError.mustBeRoot
        }
        
        try setRebootToFirmwareUI()
        
        var scriptError: NSDictionary?
        
        guard let script = NSAppleScript(source: "tell application \"System Events\" to restart") else {
                let errorMessage = "error initializing apple script"
                throw BootoptionError.internal(message: errorMessage, Location())
        }
        
        script.executeAndReturnError(&scriptError)
        
        guard scriptError == nil else {
                let errorMessage = String(describing: scriptError)
                throw BootoptionError.internal(message: errorMessage, Location())
        }
}

fileprivate func setRebootToFirmwareUI() throws {
        var osIndications: UInt64
        if let value = FirmwareVariables.default.dataValue(forGlobalVariable: "OsIndications")?.toUInt64() {
                osIndications = value | 0x1
        } else {
                osIndications = 0x1
        }
        try FirmwareVariables.default.setValue(forGlobalVariable: "OsIndications", value: osIndications.toData())
        Debug.log("NVRAM OsIndications was set", type: .info)
}
