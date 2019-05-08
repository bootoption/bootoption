/*
 * Reboot.swift
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
        
        try FirmwareVariables.default.setRebootToFirmwareUI()
        
        var scriptError: NSDictionary?
        
        guard let script = NSAppleScript(source: #"tell application "System Events" to restart"#) else {
                let errorMessage = "error initializing apple script"
                throw BootoptionError.internal(errorMessage: errorMessage, file: #file, function: #function)
        }
        
        script.executeAndReturnError(&scriptError)
        
        guard scriptError == nil else {
                let errorMessage = String(describing: scriptError)
                throw BootoptionError.internal(errorMessage: errorMessage, file: #file, function: #function)
        }
}
