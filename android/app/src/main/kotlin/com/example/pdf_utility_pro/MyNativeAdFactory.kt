package com.pdf_tools.pdf_utility_pro

import android.content.Context
import android.view.LayoutInflater
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MyNativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context).inflate(
            R.layout.my_native_ad_layout, null
        ) as NativeAdView
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView
        adView.setNativeAd(nativeAd)
        return adView
    }
}