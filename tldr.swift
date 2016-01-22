#!/usr/bin/env swift

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
    let jsonURL = NSURL(string: jsonPath)
    let jsonData = NSData(contentsOfURL: jsonURL!)

    var commands = [Command]()
    do {
        let dict = try NSJSONSerialization.JSONObjectWithData(jsonData!, options: .AllowFragments)
        if let commandsArray = dict as? NSArray {
            for command in commandsArray {
                let name = command["name"] as? String
                let platforms = command["platform"] as? [String]
                let command = Command(name: name!, platforms: platforms!)
                commands.append(command)
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
    let pageURL = NSURL(string: pagePath)
    do {
        let content = try NSString(contentsOfURL: pageURL!, encoding: NSUTF8StringEncoding)
        let lines = content.componentsSeparatedByString("\n")
        return lines
    } catch {
        print("Error loading page content.")
        exit(1)
    }
    return nil
}

func renderPageContent(pageContent: [String]) {
    for line in pageContent {
        renderLine(line)
    }
}

func renderLine(line: String) {
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

func printTitle(line: String) {
    let title = line.stringByReplacingOccurrencesOfString("# ", withString: "\n" + Styles.bold) + Styles.end
    print(title)
}

func printExplanation(line: String) {
    let explanation = String(line.characters.dropFirst(2))
    print(explanation)
}

func printExampleComment(line: String) {
    print(Styles.green + Styles.bold + line + Styles.end)
}

func printCodeExample(line: String) {
    let trimmed = String(line.characters.dropLast());
    let shifted = trimmed.stringByReplacingOccurrencesOfString("`", withString: "  ")
    var result = shifted.stringByReplacingOccurrencesOfString("{{", withString: "" + Styles.end + Styles.blueUnerline)
    result = result.stringByReplacingOccurrencesOfString("}}", withString: "" + Styles.end + Styles.boldRed)
    print(Styles.boldRed + result + Styles.end)
}

func printUsage() {
    print("Usage:")
    print("    " + Styles.boldRed + "tldr " + Styles.end + Styles.blueUnerline + "<command>" + Styles.end)
    print("    " + Styles.boldRed + "tldr " + Styles.end + Styles.blueUnerline + "<command>" + Styles.end + Styles.boldRed + " --os=" + Styles.end + Styles.blueUnerline + "linux" + Styles.end)
}

if Process.arguments.count < 2 {
    printUsage()
    exit(1)
}

var command: String? = nil
var platform = Platform.osx

for (index, argument) in Process.arguments.enumerate() {
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

let pageContent = getPage(filtered[0], platform: platform.rawValue)
renderPageContent(pageContent!)

