package com.friendly.friendly

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class FriendlySmallWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_small)
            val prefs = HomeWidgetPlugin.getData(context)

            val warmthEmoji = prefs.getString("warmth_emoji", "❄️") ?: "❄️"
            val warmthLabel = prefs.getString("warmth_label", "Quiet") ?: "Quiet"
            val friendName = prefs.getString("suggested_friend_name", "") ?: ""
            val friendInitial = prefs.getString("suggested_friend_initial", "") ?: ""
            val allCaughtUp = prefs.getBoolean("all_caught_up", true)

            if (allCaughtUp || friendName.isEmpty()) {
                views.setTextViewText(R.id.widget_emoji, "💛")
                views.setTextViewText(R.id.widget_friend_name, "All caught up")
                views.setTextViewText(R.id.widget_subtitle, "Your people are close")
                views.setTextViewText(R.id.widget_friend_initial, "")
            } else {
                views.setTextViewText(R.id.widget_emoji, "")
                views.setTextViewText(R.id.widget_friend_initial, friendInitial)
                views.setTextViewText(R.id.widget_friend_name, friendName)
                views.setTextViewText(R.id.widget_subtitle, "Say hi 👋")
            }

            views.setTextViewText(R.id.widget_warmth_badge, "$warmthEmoji $warmthLabel")

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
