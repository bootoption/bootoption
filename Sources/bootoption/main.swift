/*
 * main.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import Gaps
import BootoptionSupport

let version = "0.4.0"

var standardError = FileHandle.standardError

Debug.initialize(versionString: version)

let commandParser = BootoptionCommandParser(commands: list, info, create, order, set, delete, reboot)

do {
        try commandParser.parse()
        try commandParser.parsedCommand?.call()
}

catch let error as BootoptionError {
        switch error {
        case .usage:
                standardError.write(string: error.string)
        default:
                standardError.write(string: "error: " + error.string)
        }

        switch error {
        case .usage:
                exit(1)
        case .file:
                exit(2)
        case .mustBeRoot:
                exit(3)
        case .internal, .foundNil:
                exit(4)
        case .devicePath:
                exit(5)
        }
}
        
catch let error as FirmwareVariablesError {
        standardError.write(string: "error: " + error.string)
        exit(6)
}

catch let error as FileOptionError {
        standardError.write(string: "error: " + error.string)
        exit(7)
}

catch let error {
        fatalError(error.localizedDescription)
}
