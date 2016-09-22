#!/usr/bin/env xcrun --toolchain XcodeDefault.xctoolchain swift

import Foundation

struct Command {
    let name: String
    let platforms: [String]
}

enum Platform: String {
    case linux = "linux"
    case osx = "osx"
}

struct Styles {
    static let bold = "\u{001B}[1m"
    static let end = "\u{001B}[0m"

    static let black = "\u{001B}[0;30m"
    static let red = "\u{001B}[0;31m"
    static let green = "\u{001B}[0;32m"
    static let yellow = "\u{001B}[0;33m"
    static let blue = "\u{001B}[0;34m"
    static let magenta = "\u{001B}[0;35m"
    static let cyan = "\u{001B}[0;36m"
    static let white = "\u{001B}[0;37m"

    static let blueUnerline = "\u{001B}[4;34m"
    static let boldRed = "\u{001B}[1;31m"
}

func getCommands() -> [Command] {
    // TODO: cache commands list.
    let jsonPath = "https://raw.githubusercontent.com/tldr-pages/tldr-pages.github.io/master/assets/index.json"
    let jsonURL = URL(string: jsonPath)
    let jsonData = try! Data(contentsOf: jsonURL!)


    var commands = [Command]()
    do {
        if let dict = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] {
            if let commandsArray = dict["commands"] as? [Any] {
                for obj in commandsArray {
                    if let cmdDict = obj as? [String: Any] {
                        let name = cmdDict["name"] as? String
                        let platforms = cmdDict["platform"] as? [String]
                        let command = Command(name: name!, platforms: platforms!)
                        commands.append(command)
                    }
                }
            }
        }
    } catch {
        print("Error occured while parsing json.")
        exit(2)
    }
    return commands
}

func getPage(command: Command, platform: String) -> [String]? {
    var platformArg = command.platforms[0]
    if platformArg != platform && command.platforms.contains(platform) {
         platformArg = platform
    }
    let pagePath = "https://raw.githubusercontent.com/tldr-pages/tldr/master/pages/\(platformArg)/\(command.name).md"
    let pageURL = URL(string: pagePath)
    do {
        let content = try NSString(contentsOf: pageURL!, encoding: String.Encoding.utf8.rawValue)
        let lines = content.components(separatedBy: "\n")
        return lines
    } catch {
        print("Error loading page content.")
        exit(1)
    }
    return nil
}

func renderPageContent(_ pageContent: [String]) {
    for line in pageContent {
        renderLine(line)
    }
}

func renderLine(_ line: String) {
    if line.hasPrefix("#") {
        printTitle(line)
    } else if line.hasPrefix(">") {
        printExplanation(line)
    } else if line.hasPrefix("-") {
        printExampleComment(line)
    } else if line.hasPrefix("`") {
        printCodeExample(line)
    } else {
        print(line)
    }
}

func printTitle(_ line: String) {
    let title = line.replacingOccurrences(of: "# ", with: "\n" + Styles.bold) + Styles.end
    print(title)
}

func printExplanation(_ line: String) {
    let explanation = String(line.characters.dropFirst(2))
    print(explanation)
}

func printExampleComment(_ line: String) {
    print(Styles.green + Styles.bold + line + Styles.end)
}

func printCodeExample(_ line: String) {
    let trimmed = String(line.characters.dropLast());
    let shifted = trimmed.replacingOccurrences(of: "`", with: "  ")
    var result = shifted.replacingOccurrences(of: "{{", with: "" + Styles.end + Styles.blueUnerline)
    result = result.replacingOccurrences(of: "}}", with: "" + Styles.end + Styles.boldRed)
    print(Styles.boldRed + result + Styles.end)
}

func printUsage() {
    print("Usage:")
    print("    " + Styles.boldRed + "tldr " + Styles.end + Styles.blueUnerline + "<command>" + Styles.end)
    print("    " + Styles.boldRed + "tldr " + Styles.end + Styles.blueUnerline + "<command>" + Styles.end + Styles.boldRed + " --os=" + Styles.end + Styles.blueUnerline + "linux" + Styles.end)
}
if CommandLine.arguments.count < 2 {
    printUsage()
    exit(1)
}

var command: String? = nil
var platform = Platform.osx

for (index, argument) in CommandLine.arguments.enumerated() {
    if index == 0 {
        continue
    }

    if argument.hasPrefix("--os=") {
        let osString = String(argument.characters.dropFirst(5))
        guard let os = Platform(rawValue: osString) else {
            print("Unknown os.\n")
            printUsage()
            exit(1)
        }
        platform = os
    } else if argument == "--list" {
        let allCommands = getCommands()
        for item in allCommands {
            print("    " + item.name)
        }
        exit(0)
    } else if argument.hasPrefix("--") {
        print("Unknown parameter \(argument).\n")
    } else {
        command = argument
    }
}

guard let cmd = command else {
    printUsage()
    exit(1)
}

let allCommands = getCommands()

let filtered = allCommands.filter( { $0.name == cmd } )
if filtered.count == 0 {
    print("This page doesn't exist yet!")
    print("Submit new pages here: " + Styles.blueUnerline + "https://github.com/tldr-pages/tldr" + Styles.end)
    exit(404)
}

let pageContent = getPage(command: filtered[0], platform: platform.rawValue)
renderPageContent(pageContent!)

