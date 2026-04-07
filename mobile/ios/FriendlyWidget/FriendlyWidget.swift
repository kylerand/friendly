//
//  FriendlyWidget.swift
//  FriendlyWidget
//
//  Created by Kyle Rand on 2/17/26.
//

import WidgetKit
import SwiftUI

// ── Shared data model ────────────────────────────────────────────

struct FriendlyEntry: TimelineEntry {
    let date: Date
    let warmthEmoji: String
    let warmthLabel: String
    let weekStreak: Int
    let suggestedName: String
    let suggestedInitial: String
    let allCaughtUp: Bool
}

// ── Timeline provider — reads from home_widget shared storage ───

struct FriendlyProvider: TimelineProvider {
    private let appGroupId = "group.com.kylerand.friendly"

    func placeholder(in context: Context) -> FriendlyEntry {
        FriendlyEntry(
            date: .now, warmthEmoji: "🔥", warmthLabel: "Warm",
            weekStreak: 3, suggestedName: "Alex", suggestedInitial: "A",
            allCaughtUp: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FriendlyEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FriendlyEntry>) -> Void) {
        let entry = readEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func readEntry() -> FriendlyEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        return FriendlyEntry(
            date: .now,
            warmthEmoji: defaults?.string(forKey: "warmth_emoji") ?? "❄️",
            warmthLabel: defaults?.string(forKey: "warmth_label") ?? "Quiet",
            weekStreak: defaults?.integer(forKey: "week_streak") ?? 0,
            suggestedName: defaults?.string(forKey: "suggested_friend_name") ?? "",
            suggestedInitial: defaults?.string(forKey: "suggested_friend_initial") ?? "",
            allCaughtUp: defaults?.bool(forKey: "all_caught_up") ?? true
        )
    }
}

// ── Small widget — warmth status ─────────────────────────────────

struct FriendlySmallView: View {
    let entry: FriendlyEntry

    var body: some View {
        VStack(spacing: 6) {
            Text(entry.warmthEmoji)
                .font(.system(size: 36))
            Text(entry.warmthLabel)
                .font(.headline)
                .foregroundColor(.primary)
            if entry.weekStreak > 0 {
                Text("\(entry.weekStreak)w streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
        .widgetURL(URL(string: "friendly://home"))
    }
}

// ── Medium widget — warmth + suggestion ──────────────────────────

struct FriendlyMediumView: View {
    let entry: FriendlyEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: warmth status
            VStack(spacing: 4) {
                Text(entry.warmthEmoji)
                    .font(.system(size: 32))
                Text(entry.warmthLabel)
                    .font(.headline)
                if entry.weekStreak > 0 {
                    Text("\(entry.weekStreak)w streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right: friend suggestion
            VStack(spacing: 4) {
                if entry.allCaughtUp {
                    Text("✨")
                        .font(.system(size: 28))
                    Text("All caught up!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Text(entry.suggestedInitial)
                            .font(.title2.bold())
                            .foregroundColor(.orange)
                    }
                    Text("Reach out to")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(entry.suggestedName)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
        .widgetURL(URL(string: entry.allCaughtUp
            ? "friendly://home"
            : "friendly://home"))
    }
}

// ── Lock screen widgets (iOS 16+) ────────────────────────────────

struct FriendlyLockCircular: View {
    let entry: FriendlyEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Text(entry.warmthEmoji)
                .font(.title2)
        }
    }
}

struct FriendlyLockRectangular: View {
    let entry: FriendlyEntry

    var body: some View {
        HStack(spacing: 6) {
            Text(entry.warmthEmoji)
                .font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.warmthLabel)
                    .font(.headline)
                if !entry.allCaughtUp {
                    Text("Reach out to \(entry.suggestedName)")
                        .font(.caption)
                        .lineLimit(1)
                } else {
                    Text("All caught up ✨")
                        .font(.caption)
                }
            }
        }
    }
}

// ── Widget declarations ──────────────────────────────────────────

struct FriendlyHomeWidget: Widget {
    let kind = "FriendlyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FriendlyProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                switch WidgetFamily.systemSmall {
                default:
                    FriendlySmallView(entry: entry)
                }
            } else {
                FriendlySmallView(entry: entry)
            }
        }
        .configurationDisplayName("Friendly Warmth")
        .description("See your friendship warmth at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct FriendlyLockWidget: Widget {
    let kind = "FriendlyLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FriendlyProvider()) { entry in
            if #available(iOSApplicationExtension 16.0, *) {
                FriendlyLockCircular(entry: entry)
            }
        }
        .configurationDisplayName("Friendly")
        .description("Warmth status on your lock screen.")
        .supportedFamilies(lockFamilies)
    }

    private var lockFamilies: [WidgetFamily] {
        if #available(iOSApplicationExtension 16.0, *) {
            return [.accessoryCircular, .accessoryRectangular]
        }
        return []
    }
}

// ── Previews ─────────────────────────────────────────────────────

#Preview("Small", as: .systemSmall) {
    FriendlyHomeWidget()
} timeline: {
    FriendlyEntry(
        date: .now, warmthEmoji: "🔥", warmthLabel: "Warm",
        weekStreak: 3, suggestedName: "Alex", suggestedInitial: "A",
        allCaughtUp: false
    )
}

#Preview("Medium", as: .systemMedium) {
    FriendlyHomeWidget()
} timeline: {
    FriendlyEntry(
        date: .now, warmthEmoji: "☀️", warmthLabel: "Radiant",
        weekStreak: 5, suggestedName: "", suggestedInitial: "",
        allCaughtUp: true
    )
}
