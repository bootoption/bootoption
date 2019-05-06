/*
 * BootoptionCommandParser.swift
 * Copyright © 2019 vulgo
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Gaps

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
