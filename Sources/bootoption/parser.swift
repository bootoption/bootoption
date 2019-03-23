/*
 * parser.swift
 * Copyright © 2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation
import Gaps
import BootoptionSupport

struct Options {
        static let active = AttributeOption(flags: "active", helpMessage: "active attribute value (0 or 1)")
        static let hidden = AttributeOption(flags: "hidden", helpMessage: "hidden attribute value (0 or 1)")
        static let bootNumber = BootNumberOption(flags: "n", "name", helpMessage: "the variable to manipulate, Boot####")
        static let deleteBootNext = BooleanOption(flags: "x", "bootnext", helpMessage: "unset BootNext")
        static let deleteBootOrder = BooleanOption(flags: "o", "bootorder", helpMessage: "delete BootOrder")
        static let deleteTimeout = BooleanOption(flags: "t", "timeout", helpMessage: "unset Timeout")
        static let description = StringOption(flags: "d", "description", helpMessage: "display LABEL in firmware boot manager")
        static let loaderPath = FileForReadingOption(flags: "l", "loader", helpMessage: "the PATH to the EFI loader")
        static let optionalDataFile = FileForReadingOption(flags: "@", "optional-data", helpMessage: "append optional data from FILE")
        static let optionalDataString = OptionalStringOption(flags: "a", "arguments", helpMessage: "an optional STRING passed to the loader command line")
        static let printBootOrder = BooleanOption(flags: "p", "print", helpMessage: nil)
        static let setBootNext = BootNumberOption(flags: "x", "bootnext", helpMessage: "set BootNext to Boot####")
        static let setBootOrder = BootOrderArrayOption(flags: "o", "bootorder", helpMessage: "set the boot order explicitly")
        static let setTimeout = TimeoutOption(flags: "t", "timeout", helpMessage: "set the boot menu Timeout in SECONDS")
        static let outputToFile = FileForWritingOption(flags: "t", "test", helpMessage: "output to FILE instead of NVRAM")
        static let useUCS2 = BooleanOption(flags: "u", helpMessage: "pass command line arguments as UCS-2 instead of ASCII")
        static let verbose = BooleanOption(flags: "v", "verbose")
}

final class BootoptionCommandParser: CommandParser {     
        override var helpArgument: String? {
                return "--help"
        }
        
        override var versionArgument: String? {
                return "--version"
        }
        
        override func printVersion() {
                print("bootoption " + version + " Copyright © 2017-2019 vulgo")
                print("""
                This is free software: you are free to change and redistribute it.
                There is NO WARRANTY, to the extent permitted by law.
                See the GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
                """)
        }
}

final class BootNumberOption: Option {
        public init(flags: String ..., helpMessage: String? = nil, required: Bool = false) {
                super.init(flags, helpMessage, required)
        }
        
        private(set) var value: BootNumber? = nil {
                didSet {
                        wasSet = true
                }
        }
        
        override public func claimValue(_ argument: String?) throws {
                switch argument {
                case .none:
                        if wasSet == true {
                                throw ParserError.invalidUsage(option: self)
                        } else {
                                throw ParserError.missingRequiredValue(option: self)
                        }
                case .some:
                        guard value == nil else {
                                throw ParserError.unparsedArgument(argument!)
                        }
                        guard let newValue = try argument!.toBootNumber() else {
                                invalidValue = argument!
                                throw ParserError.invalidValue(option: self, argument: argument!)
                        }
                        value = newValue
                }
        }
        
        override public func reset() {
                value = nil
                wasSet = false
        }
}

final class TimeoutOption: Option {
        public init(flags: String ..., helpMessage: String? = nil, required: Bool = false) {
                super.init(flags, helpMessage, required)
        }
        
        private(set) var value: UInt16? {
                didSet {
                        wasSet = true
                }
        }
        
        override public func claimValue(_ argument: String?) throws {
                switch argument {
                case .none:
                        if wasSet == true {
                                throw ParserError.invalidUsage(option: self)
                        } else {
                                throw ParserError.missingRequiredValue(option: self)
                        }
                case .some:
                        guard value == nil else {
                                throw ParserError.unparsedArgument(argument!)
                        }
                        guard let newValue = UInt16(argument!) else {
                                invalidValue = argument!
                                throw ParserError.invalidValue(option: self, argument: argument!)
                        }
                        value = newValue
                }
        }
        
        override public func reset() {
                value = nil
                wasSet = false
        }
}

final class BootOrderArrayOption: Option {
        public init(flags: String ..., helpMessage: String? = nil, required: Bool = false) {
                super.init(flags, helpMessage, required)
        }
        
        private(set) var value: [BootNumber]? {
                didSet {
                        wasSet = true
                }
        }
        
        override public func claimValue(_ argument: String?) throws {
                switch argument {
                case .none:
                        if wasSet == true {
                                throw ParserError.invalidUsage(option: self)
                        } else {
                                throw ParserError.missingRequiredValue(option: self)
                        }
                case .some:
                        if value == nil {
                                value = [BootNumber]()
                        }
                        guard let bootNumber = try argument!.toBootNumber() else {
                                throw ParserError.invalidValue(option: self, argument: argument!)
                        }
                        if let value = value, value.contains(bootNumber) {
                                throw ParserError.invalidValue(option: self, argument: argument!)
                        }
                        value!.append(bootNumber)
                }
        }
        
        override public func reset() {
                value = nil
                wasSet = false
        }
}

final class AttributeOption: Option {
        public init(flags: String ..., helpMessage: String? = nil, required: Bool = false) {
                super.init(flags, helpMessage, required)
        }
        
        private(set) var value: Bool? {
                didSet {
                        wasSet = true
                }
        }
        
        override public func claimValue(_ argument: String?) throws {
                switch argument {
                case .none:
                        if wasSet == true {
                                throw ParserError.invalidUsage(option: self)
                        } else {
                                throw ParserError.missingRequiredValue(option: self)
                        }
                case .some:
                        guard value == nil else {
                                throw ParserError.unparsedArgument(argument!)
                        }
                        switch argument!.lowercased() {
                        case "0", "false", "no":
                                value = false
                                return
                        case "1", "true", "yes":
                                value = true
                                return
                        default:
                                break
                        }
                        invalidValue = argument!
                        throw ParserError.invalidValue(option: self, argument: argument!)
                }
        }
        
        override public func reset() {
                value = nil
                wasSet = false
        }
}
