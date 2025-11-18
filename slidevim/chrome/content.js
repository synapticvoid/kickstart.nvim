// Slidevim - Chrome extension content script
// Syncs sli.dev preview with Neovim cursor position

(function() {
  'use strict';

  const WS_URL = 'ws://localhost:8765';
  let ws = null;
  let reconnectTimer = null;
  let reconnectDelay = 1000;
  const MAX_RECONNECT_DELAY = 30000;

  // Extract current slide number from URL
  function getCurrentSlide() {
    // Sli.dev uses: http://localhost:3030/5 or /#5 or ?slide=5
    const hash = window.location.hash.match(/#(\d+)/);
    if (hash) return parseInt(hash[1], 10);

    const path = window.location.pathname.match(/\/(\d+)$/);
    if (path) return parseInt(path[1], 10);

    const query = new URLSearchParams(window.location.search).get('slide');
    if (query) return parseInt(query, 10);

    return 1; // Default to slide 1
  }

  // Navigate to a specific slide
  function gotoSlide(slideNum) {
    if (!slideNum || slideNum < 1) return;

    // Try hash-based navigation first (most common in Sli.dev)
    if (window.location.hash) {
      window.location.hash = `#${slideNum}`;
    } else if (window.location.pathname.match(/\/\d+$/)) {
      // Path-based navigation
      const newPath = window.location.pathname.replace(/\/\d+$/, `/${slideNum}`);
      window.history.pushState(null, '', newPath);
      window.dispatchEvent(new PopStateEvent('popstate'));
    } else {
      // Fallback: append to path
      const base = window.location.pathname.replace(/\/$/, '');
      window.history.pushState(null, '', `${base}/${slideNum}`);
      window.dispatchEvent(new PopStateEvent('popstate'));
    }
  }

  // Send current slide to Neovim
  function sendSlideToNeovim(slideNum) {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ type: 'navigate', slide: slideNum }));
      console.log('[Slidevim] Sent to Neovim: slide', slideNum);
    }
  }

  // Handle messages from Neovim
  function handleMessage(event) {
    try {
      const msg = JSON.parse(event.data);
      if (msg.type === 'goto' && msg.slide) {
        console.log('[Slidevim] Goto slide:', msg.slide);
        gotoSlide(msg.slide);
      }
    } catch (err) {
      console.error('[Slidevim] Message parse error:', err);
    }
  }

  // Connect to Neovim WebSocket server
  function connect() {
    if (ws && (ws.readyState === WebSocket.CONNECTING || ws.readyState === WebSocket.OPEN)) {
      return; // Already connected or connecting
    }

    console.log('[Slidevim] Connecting to', WS_URL);
    ws = new WebSocket(WS_URL);

    ws.onopen = () => {
      console.log('[Slidevim] Connected');
      reconnectDelay = 1000; // Reset backoff
      
      // Send initial slide position
      const currentSlide = getCurrentSlide();
      sendSlideToNeovim(currentSlide);
    };

    ws.onmessage = handleMessage;

    ws.onclose = () => {
      console.log('[Slidevim] Disconnected');
      scheduleReconnect();
    };

    ws.onerror = (err) => {
      console.error('[Slidevim] WebSocket error:', err);
      ws.close();
    };
  }

  // Reconnect with exponential backoff
  function scheduleReconnect() {
    if (reconnectTimer) return;

    reconnectTimer = setTimeout(() => {
      reconnectTimer = null;
      reconnectDelay = Math.min(reconnectDelay * 1.5, MAX_RECONNECT_DELAY);
      connect();
    }, reconnectDelay);
  }

  // Listen for slide changes in the preview
  let lastSlide = getCurrentSlide();

  function onNavigationChange() {
    const currentSlide = getCurrentSlide();
    if (currentSlide !== lastSlide) {
      lastSlide = currentSlide;
      sendSlideToNeovim(currentSlide);
    }
  }

  // Monitor hash, path, and history changes
  window.addEventListener('hashchange', onNavigationChange);
  window.addEventListener('popstate', onNavigationChange);

  // Also monitor for SPA navigation (MutationObserver for URL changes)
  let lastUrl = window.location.href;
  new MutationObserver(() => {
    if (window.location.href !== lastUrl) {
      lastUrl = window.location.href;
      onNavigationChange();
    }
  }).observe(document.querySelector('body'), { childList: true, subtree: true });

  // Initialize connection
  connect();

  console.log('[Slidevim] Content script loaded');
})();
