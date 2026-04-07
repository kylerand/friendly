//
//  FriendlyWidgetBundle.swift
//  FriendlyWidget
//
//  Created by Kyle Rand on 2/17/26.
//

import WidgetKit
import SwiftUI

@main
struct FriendlyWidgetBundle: WidgetBundle {
    var body: some Widget {
        FriendlyHomeWidget()
        FriendlyLockWidget()
    }
}
