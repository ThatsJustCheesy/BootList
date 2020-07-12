//
//  ContentView.swift
//  BootList
//
//  Created by Ian Gregory on 11 Jul ’20.
//  Copyright © 2020 Ian Gregory. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var entries: [EFIEntry]
    var currentlyBooted: UInt

    var body: some View {
        VStack {
            List(entries) { entry in
                HStack {
                    Group {
                        if entry.id == self.currentlyBooted {
                            Image("checkmark").resizable().scaledToFit()
                        } else {
                            Rectangle().foregroundColor(.transparent)
                        }
                    }
                    .frame(width: 16, height: 16, alignment: .center)

                    Text(entry.formattedID)
                    Text(entry.label)
                }
                .font(Font.system(size: 14).monospacedDigit())
                .frame(minHeight: 40, alignment: .leading)

                Spacer()

                Button(action: {
                    guard let bootoption = bootoptionURL() else {
                        NSApp.presentError(BootoptionUnavailable())
                        return NSApp.terminate(nil)
                    }

                    var error: NSDictionary?
                    NSAppleScript(source: """
                        do shell script "\(bootoption.path) set -x \(String(entry.id, radix: 16))" with administrator privileges
                        tell app "System Events" to restart
                    """)?.executeAndReturnError(&error)

                    if let error = error {
                        struct AppleScriptError: LocalizedError {
                            var errorDescription: String?
                        }
                        NSApp.presentError(AppleScriptError(errorDescription: error.value(forKey: NSAppleScript.errorMessage) as? String))
                        return
                    }
                }) {
                    Text("Boot \(entry.label)").frame(minWidth: 40, idealWidth: 180, maxWidth: 180, alignment: .center)
                    Image(nsImage: NSImage(named: NSImage.goForwardTemplateName)!)
                }
            }
        }
        .padding()
    }
}

extension Color {
    static var transparent: Color {
        Color(hue: 0, saturation: 0, brightness: 0, opacity: 0)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(entries: [
            EFIEntry(id: 0000, label: "ubuntu"),
            EFIEntry(id: 0001, label: "Windows Boot Manager"),
            EFIEntry(id: 0080, label: "Mac OS X"),
            EFIEntry(id: 0081, label: "Mac OS X")
        ], currentlyBooted: 0080)
    }
}
