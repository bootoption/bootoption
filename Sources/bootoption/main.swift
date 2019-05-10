/*
 * main.swift
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import Gaps
import BootoptionSupport

let version = "0.6.0"

Debug.initialize(versionString: version)

let commandParser = BootoptionCommandParser(commands: list, info, create, order, set, delete, reboot)

do {
        try commandParser.parse()
        try commandParser.parsedCommand?.call()
}

catch let error as CustomStringConvertible {
        switch error {
        case BootoptionError.usage:
                FileHandle.standardError.write(string: "\(error)")
        default:
                FileHandle.standardError.write(string: "error: \(error)")
        }
        exit(1)
}

catch let error {
        fatalError(error.localizedDescription)
}
