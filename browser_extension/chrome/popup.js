document.addEventListener("DOMContentLoaded", () => {
  const interceptToggle = document.getElementById("interceptToggle");
  const extInput = document.getElementById("extInput");
  const saveBtn = document.getElementById("saveBtn");
  const analyzeTabBtn = document.getElementById("analyzeTabBtn");
  const engineStatus = document.getElementById("engineStatus");
  const connectionInfo = document.getElementById("connectionInfo");

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

  // Check Backend Connection via HTTP REST
  fetch("http://127.0.0.1:8000/api/health", { method: "GET" })
    .then((res) => res.json())
    .then((data) => {
      if (data.status === "ok") {
        engineStatus.innerHTML = '<span class="status-dot" style="background:#00E676;box-shadow:0 0 6px #00E676"></span> Connected';
        engineStatus.style.color = '#00E676';
        engineStatus.style.borderColor = 'rgba(0,230,118,0.3)';
        engineStatus.style.background = 'rgba(0,230,118,0.1)';
        connectionInfo.innerText = `FastAPI Core v${data.version} Connected`;
      } else {
        checkNativeFallback();
      }
    })
    .catch(() => {
      checkNativeFallback();
    });

  function checkNativeFallback() {
    try {
      const port = chrome.runtime.connectNative("com.netpulse.downloader");
      port.postMessage({ action: "ping" });
      port.onMessage.addListener((msg) => {
        if (msg.status === "ok") {
          engineStatus.innerHTML = '<span class="status-dot"></span> Native Bridge';
          connectionInfo.innerText = "Native Messaging Connected";
        }
        port.disconnect();
      });
      port.onDisconnect.addListener(() => {
        engineStatus.innerHTML = '<span class="status-dot" style="background:#FF5252;box-shadow:0 0 6px #FF5252"></span> Offline';
        engineStatus.style.color = '#FF5252';
        engineStatus.style.borderColor = 'rgba(255,82,82,0.3)';
        engineStatus.style.background = 'rgba(255,82,82,0.1)';
        connectionInfo.innerText = "Launch NetPulse Desktop App";
      });
    } catch (_) {
      engineStatus.innerHTML = '<span class="status-dot" style="background:#FF5252"></span> Disconnected';
      connectionInfo.innerText = "Launch NetPulse Desktop App";
    }
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

  // Analyze current active tab
  analyzeTabBtn.addEventListener("click", () => {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
      if (tabs && tabs[0] && tabs[0].url) {
        analyzeTabBtn.innerText = "Analyzing...";
        fetch("http://127.0.0.1:8000/api/browser/analyze", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ url: tabs[0].url })
        })
          .then((r) => r.json())
          .then((data) => {
            analyzeTabBtn.innerText = `Found ${data.total_discovered || 0} Files!`;
            setTimeout(() => {
              analyzeTabBtn.innerText = "Analyze Tab";
            }, 3000);
          })
          .catch(() => {
            analyzeTabBtn.innerText = "Offline";
            setTimeout(() => {
              analyzeTabBtn.innerText = "Analyze Tab";
            }, 2000);
          });
      }
    });
  });
});
