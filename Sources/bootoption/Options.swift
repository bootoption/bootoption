/*
 * Options.swift
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
        static let deleteBootNext = FlagOption(flags: "x", "bootnext", helpMessage: "unset BootNext")
        static let deleteBootOrder = FlagOption(flags: "o", "bootorder", helpMessage: "delete BootOrder")
        static let deleteTimeout = FlagOption(flags: "t", "timeout", helpMessage: "unset Timeout")
        static let description = StringOption(flags: "d", "description", helpMessage: "display LABEL in firmware boot manager")
        static let loaderPath = FileForReadingOption(flags: "l", "loader", helpMessage: "the PATH to the EFI loader")
        static let optionalDataFile = FileForReadingOption(flags: "@", "optional-data", helpMessage: "append optional data from FILE")
        static let optionalDataString = StringOption(flags: "a", "arguments", helpMessage: "an optional STRING passed to the loader command line", valueIsOptional: true)
        static let printBootOrder = FlagOption(flags: "p", "print", helpMessage: nil)
        static let setBootNext = BootNumberOption(flags: "x", "bootnext", helpMessage: "set BootNext to Boot####")
        static let setBootOrder = BootOrderArrayOption(flags: "o", "bootorder", helpMessage: "set the boot order explicitly", valueIsOptional: true)
        static let setTimeout = TimeoutOption(flags: "t", "timeout", helpMessage: "set the boot menu Timeout in SECONDS")
        static let outputToFile = FileForWritingOption(flags: "t", "test", helpMessage: "output to FILE instead of NVRAM")
        static let useUCS2 = FlagOption(flags: "u", helpMessage: "pass command line arguments as UCS-2 instead of ASCII")
        static let verbose = FlagOption(flags: "v", "verbose")
        
        final class BootNumberOption: Option<BootNumber>, OptionProtocol {
                func claimValue(argument: String) throws {
                        guard !wasSet else {
                                throw ParserError.unparsedArgument(argument)
                        }
                        
                        value = try BootNumber(variableName: argument)
                }
        }
        
        final class BootOrderArrayOption: Option<Array<BootNumber>>, OptionProtocol {
                override public func claimValue() throws {
                        guard !wasSet else {
                                throw ParserError.invalidUse(optionDescription: self.description)
                        }
                        
                        guard valueIsOptional else {
                                throw ParserError.missingRequiredValue(optionDescription: self.description)
                        }
                        
                        value = [BootNumber]()
                }
                
                public func claimValue(argument: String) throws {
                        let element = try BootNumber(variableName: argument)
                        
                        if value == nil {
                                value = [BootNumber]()
                        }
                        
                        value!.append(element)
                }
        }
        
        final class AttributeOption: Option<Bool>, OptionProtocol {
                func claimValue(argument: String) throws {
                        guard !wasSet else {
                                throw ParserError.unparsedArgument(argument)
                        }
                        
                        var newValue: Bool
                        
                        switch argument.lowercased() {
                        case "0", "false", "no":
                                newValue = false
                        case "1", "true", "yes":
                                newValue = true
                        default:
                                throw ParserError.invalidValue(optionDescription: self.description, argument: argument)
                        }
                        
                        value = newValue
                }
        }
        
        final class TimeoutOption: StringConvertibleOption<UInt16>, OptionProtocol { }
}
