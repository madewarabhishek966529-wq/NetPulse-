// NetPulse Browser Integration - Background Service Worker
const NATIVE_HOST = "com.netpulse.downloader";
const BACKEND_BASE_URL = "http://127.0.0.1:8000";

// Setup context menu
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "netpulse-download-link",
    title: "Download with NetPulse",
    contexts: ["link", "video", "audio", "image"]
  });

  chrome.contextMenus.create({
    id: "netpulse-analyze-page",
    title: "Analyze page with NetPulse",
    contexts: ["page"]
  });

  // Default settings
  chrome.storage.local.get(["interceptionEnabled", "extensions"], (res) => {
    if (res.interceptionEnabled === undefined) {
      chrome.storage.local.set({
        interceptionEnabled: true,
        extensions: "exe,msi,zip,rar,7z,iso,tar,gz,mp4,mkv,avi,mp3,flac,pdf"
      });
    }
  });
});

// Handle Context Menu clicks
chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === "netpulse-download-link") {
    const targetUrl = info.linkUrl || info.srcUrl;
    if (targetUrl) {
      sendToNetPulse(targetUrl, "", tab ? tab.url : "");
    }
  } else if (info.menuItemId === "netpulse-analyze-page") {
    const pageUrl = info.pageUrl || (tab ? tab.url : "");
    if (pageUrl) {
      analyzePageWithNetPulse(pageUrl);
    }
  }
});

// Intercept browser downloads
chrome.downloads.onCreated.addListener(async (downloadItem) => {
  chrome.storage.local.get(["interceptionEnabled", "extensions"], (res) => {
    if (!res.interceptionEnabled) return;

    const url = downloadItem.finalUrl || downloadItem.url;
    if (!url || url.startsWith("blob:") || url.startsWith("data:")) return;

    // Check extension
    const extList = (res.extensions || "").split(",").map(e => e.trim().toLowerCase());
    const filename = downloadItem.filename || "";
    const extMatch = filename.split(".").pop().toLowerCase();

    const isMatch = extList.includes(extMatch) || extList.some(e => url.toLowerCase().includes("." + e));

    if (isMatch) {
      // Cancel browser's native download
      chrome.downloads.cancel(downloadItem.id, () => {
        chrome.downloads.erase({ id: downloadItem.id });
      });

      sendToNetPulse(url, filename, downloadItem.referrer || "");
    }
  });
});

async function sendToNetPulse(url, fileName, referrer) {
  // 1. Try Direct HTTP REST API to local NetPulse FastAPI backend
  try {
    const response = await fetch(`${BACKEND_BASE_URL}/api/browser/link`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        url: url,
        filename: fileName || "",
        referrer: referrer || "",
        source: "chrome"
      })
    });

    if (response.ok) {
      const data = await response.json();
      chrome.notifications.create({
        type: "basic",
        iconUrl: "icons/icon48.png",
        title: "NetPulse Accelerated Download",
        message: `Forwarded to NetPulse: ${data.filename || fileName || "New Download"}`
      });
      return;
    }
  } catch (httpErr) {
    console.warn("Direct HTTP to NetPulse backend failed, falling back to Native Messaging:", httpErr);
  }

  // 2. Fallback to Chrome Native Messaging
  try {
    const port = chrome.runtime.connectNative(NATIVE_HOST);
    port.postMessage({
      action: "download",
      url: url,
      fileName: fileName,
      referrer: referrer
    });

    port.onMessage.addListener((response) => {
      chrome.notifications.create({
        type: "basic",
        iconUrl: "icons/icon48.png",
        title: "NetPulse Accelerated Download",
        message: response.status === "success" 
          ? `Forwarded to NetPulse: ${fileName || "New Download"}`
          : `Notice: ${response.message}`
      });
      port.disconnect();
    });

    port.onDisconnect.addListener(() => {
      if (chrome.runtime.lastError) {
        chrome.notifications.create({
          type: "basic",
          iconUrl: "icons/icon48.png",
          title: "NetPulse Not Connected",
          message: "Please launch NetPulse desktop application to enable download acceleration."
        });
      }
    });
  } catch (nativeErr) {
    console.error("Both HTTP API and Native messaging failed:", nativeErr);
  }
}

async function analyzePageWithNetPulse(pageUrl) {
  try {
    chrome.notifications.create({
      type: "basic",
      iconUrl: "icons/icon48.png",
      title: "NetPulse Smart Analyzer",
      message: `Analyzing webpage: ${pageUrl}...`
    });

    const response = await fetch(`${BACKEND_BASE_URL}/api/browser/analyze`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url: pageUrl })
    });

    if (response.ok) {
      const data = await response.json();
      chrome.notifications.create({
        type: "basic",
        iconUrl: "icons/icon48.png",
        title: "NetPulse Analysis Complete",
        message: `Discovered ${data.total_discovered || 0} files (${data.total_filtered || 0} ads filtered). Open NetPulse to download.`
      });
    }
  } catch (err) {
    chrome.notifications.create({
      type: "basic",
      iconUrl: "icons/icon48.png",
      title: "NetPulse Analyzer Notice",
      message: "Please launch NetPulse desktop application to inspect this page."
    });
  }
}
