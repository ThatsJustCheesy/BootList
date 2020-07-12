//
//  AppDelegate.swift
//  BootList
//
//  Created by Ian Gregory on 11 Jul ’20.
//  Copyright © 2020 Ian Gregory. All rights reserved.
//

import Cocoa
import SwiftUI
import Regex

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    func applicationWillFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [
            "bootoption": "/usr/local/bin/bootoption"
        ])
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        fetchEFIEntries { result in
            switch result {
            case let .failure(error):
                guard NSApp.presentError(error) else {
                    return NSApp.terminate(self)
                }
            case let .success((currentlyBooted: currentlyBooted, all: efiEntries)):
                // Create the SwiftUI view that provides the window contents.
                let contentView = ContentView(
                    entries: efiEntries,
                    currentlyBooted: currentlyBooted
                )

                // Create the window and set the content view.
                window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                    styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                    backing: .buffered, defer: false
                )
                window.title = "BootList"
                window.center()
                window.setFrameAutosaveName("Main Window")
                window.contentView = NSHostingView(rootView: contentView)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    func fetchEFIEntries(then completion: (Result<(currentlyBooted: UInt, all: [EFIEntry]), Error>) -> Void) {
        runBootoption(arguments: ["list"]) { result in
            switch result {
            case let .failure(error):
                return completion(.failure(error))
            case let .success(output):
                guard let bootCurrentMatch = Regex("BootCurrent: Boot([0-9a-fA-F]{4})").firstMatch(in: output) else {
                    struct InvalidOutput: LocalizedError {
                        var errorDescription: String? {
                            "Could not parse the output of the 'bootoption' tool."
                        }
                    }
                    return completion(.failure(InvalidOutput()))
                }
                let currentlyBootedID = UInt(bootCurrentMatch.captures[0]!, radix: 16)!

                // Ignore the first three lines of output.
                let bootEntryLines = output.split(separator: "\n")[3...]

                // Parse the remaining lines for boot menu entries.
                let regex = Regex("Boot([0-9a-fA-F]{4}) (.+)")
                let entries: [EFIEntry] = bootEntryLines.compactMap { line in
                    guard let match = regex.firstMatch(in: String(line)) else {
                        return nil
                    }
                    let id = UInt(match.captures[0]!, radix: 16)!
                    let label = match.captures[1]!
                    return EFIEntry(id: id, label: label)
                }

                completion(.success((currentlyBooted: currentlyBootedID, all: entries)))
            }
        }
    }

}

func runBootoption(arguments: [String], then completion: (Result<String, Error>) -> Void) {
    guard let bootoption = bootoptionURL() else {
        NSApp.presentError(BootoptionUnavailable())
        return NSApp.terminate(nil)
    }

    let process = Process()
    process.executableURL = bootoption
    process.arguments = arguments
    let out = Pipe()
    process.standardOutput = out

    do {
        try process.run()
        guard
            let resultData = try out.fileHandleForReading.readToEnd(),
            let resultString = String(data: resultData, encoding: .utf8)
        else {
            struct ReadError: LocalizedError {
                var errorDescription: String? {
                    "Could not read the output of the 'bootoption' tool."
                }
            }
            throw ReadError()
        }
        return completion(.success(resultString))
    } catch {
        return completion(.failure(error))
    }
}

struct BootoptionUnavailable: LocalizedError {
    var errorDescription: String? {
        "bootoption is unavailable. Please install it via homebrew:\n\nbrew install bootoption"
    }
}

func bootoptionURL() -> URL? {
    guard
        let path = UserDefaults.standard.string(forKey: "bootoption"),
        FileManager.default.isExecutableFile(atPath: path)
    else {
        return nil
    }
    return URL(fileURLWithPath: path)
}
