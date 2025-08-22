//
//  MiniWidgetsBundle.swift
//  MiniWidgets
//
//  Created by Emre Can Mece on 12.08.2025.
//

import WidgetKit
import SwiftUI

@main
struct MiniWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MiniWidgets()
        MiniWidgetsControl()
        MiniWidgetsLiveActivity()
    }
}
