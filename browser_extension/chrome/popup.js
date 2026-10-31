document.addEventListener("DOMContentLoaded", () => {
  const interceptToggle = document.getElementById("interceptToggle");
  const extInput = document.getElementById("extInput");
  const saveBtn = document.getElementById("saveBtn");
  const engineStatus = document.getElementById("engineStatus");

  // Load saved preferences
  chrome.storage.local.get(["interceptionEnabled", "extensions"], (res) => {
    if (res.interceptionEnabled !== undefined) {
      interceptToggle.checked = res.interceptionEnabled;
    }
    if (res.extensions) {
      extInput.value = res.extensions;
    } else {
      extInput.value = "exe,msi,zip,rar,7z,iso,tar,gz,mp4,mkv,avi,mp3,flac,pdf";
    }
  });

  // Test native host ping
  try {
    const port = chrome.runtime.connectNative("com.netpulse.downloader");
    port.postMessage({ action: "ping" });
    port.onMessage.addListener((msg) => {
      if (msg.status === "ok") {
        engineStatus.innerHTML = '<span class="status-dot"></span> Connected';
      }
      port.disconnect();
    });
    port.onDisconnect.addListener(() => {
      engineStatus.innerHTML = '<span class="status-dot" style="background:#FF5252;box-shadow:0 0 6px #FF5252"></span> Offline';
      engineStatus.style.color = '#FF5252';
      engineStatus.style.borderColor = 'rgba(255,82,82,0.3)';
      engineStatus.style.background = 'rgba(255,82,82,0.1)';
    });
  } catch (_) {
    engineStatus.innerHTML = '<span class="status-dot" style="background:#FF5252"></span> Disconnected';
  }

  // Save preferences
  saveBtn.addEventListener("click", () => {
    chrome.storage.local.set({
      interceptionEnabled: interceptToggle.checked,
      extensions: extInput.value.trim()
    }, () => {
      saveBtn.innerText = "Saved!";
      setTimeout(() => {
        saveBtn.innerText = "Save Preferences";
      }, 1500);
    });
  });
});
