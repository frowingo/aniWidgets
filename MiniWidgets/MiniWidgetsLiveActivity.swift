//
//  MiniWidgetsLiveActivity.swift
//  MiniWidgets
//
//  Created by Emre Can Mece on 12.08.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MiniWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MiniWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MiniWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MiniWidgetsAttributes {
    fileprivate static var preview: MiniWidgetsAttributes {
        MiniWidgetsAttributes(name: "World")
    }
}

extension MiniWidgetsAttributes.ContentState {
    fileprivate static var smiley: MiniWidgetsAttributes.ContentState {
        MiniWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MiniWidgetsAttributes.ContentState {
         MiniWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MiniWidgetsAttributes.preview) {
   MiniWidgetsLiveActivity()
} contentStates: {
    MiniWidgetsAttributes.ContentState.smiley
    MiniWidgetsAttributes.ContentState.starEyes
}
