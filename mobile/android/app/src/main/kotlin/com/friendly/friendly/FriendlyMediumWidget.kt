package com.friendly.friendly

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class FriendlyMediumWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_medium)
            val prefs = HomeWidgetPlugin.getData(context)

            val warmthEmoji = prefs.getString("warmth_emoji", "❄️") ?: "❄️"
            val warmthLabel = prefs.getString("warmth_label", "Quiet") ?: "Quiet"
            val weekStreak = prefs.getInt("week_streak", 0)
            val friendName = prefs.getString("suggested_friend_name", "") ?: ""
            val friendInitial = prefs.getString("suggested_friend_initial", "") ?: ""
            val allCaughtUp = prefs.getBoolean("all_caught_up", true)

            views.setTextViewText(R.id.widget_warmth_emoji, warmthEmoji)
            views.setTextViewText(R.id.widget_warmth_label, warmthLabel)
            views.setTextViewText(
                R.id.widget_streak,
                if (weekStreak > 0) "$weekStreak week streak" else ""
            )

            if (allCaughtUp || friendName.isEmpty()) {
                views.setTextViewText(R.id.widget_friend_initial, "💛")
                views.setTextViewText(R.id.widget_friend_label, "All caught up")
            } else {
                views.setTextViewText(R.id.widget_friend_initial, friendInitial)
                views.setTextViewText(R.id.widget_friend_label, "Say hi to $friendName")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
