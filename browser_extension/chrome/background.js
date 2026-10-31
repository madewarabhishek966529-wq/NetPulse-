// NetPulse Browser Integration - Background Service Worker
const NATIVE_HOST = "com.netpulse.downloader";

// Setup context menu
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "netpulse-download-link",
    title: "Download with NetPulse",
    contexts: ["link", "video", "audio", "image"]
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

// Handle Context Menu click
chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === "netpulse-download-link") {
    const targetUrl = info.linkUrl || info.srcUrl;
    if (targetUrl) {
      sendToNetPulse(targetUrl, "", tab ? tab.url : "");
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

function sendToNetPulse(url, fileName, referrer) {
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
          title: "NetPulse Not Detected",
          message: "Please launch NetPulse or run register_host.bat to enable browser integration."
        });
      }
    });
  } catch (err) {
    console.error("Native messaging error:", err);
  }
}
