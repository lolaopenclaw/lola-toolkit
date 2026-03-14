// Lightweight ad-blocking CSS injection for Chrome CDP
// Hides common ad containers, tracking iframes, and sponsored content
// Injected via CDP Page.addScriptToEvaluateOnNewDocument

(function() {
  const style = document.createElement('style');
  style.textContent = `
    /* Generic ad containers */
    [class*="ad-container"], [class*="ad_container"],
    [class*="ad-wrapper"], [class*="ad_wrapper"],
    [class*="adslot"], [class*="ad-slot"],
    [id*="ad-container"], [id*="ad_container"],
    [id*="google_ads"], [id*="div-gpt-ad"],
    [data-ad], [data-ad-slot],
    
    /* Google Ads */
    .adsbygoogle, ins.adsbygoogle,
    
    /* Sponsored content */
    [class*="sponsored"], [class*="Sponsored"],
    [class*="publi"], [class*="Publi"],
    
    /* Tracking iframes */
    iframe[src*="doubleclick"],
    iframe[src*="googlesyndication"],
    iframe[src*="amazon-adsystem"],
    iframe[src*="criteo"],
    iframe[src*="pubmatic"],
    iframe[src*="adnxs"],
    iframe[src*="safeframe"],
    iframe[src*="2mdn.net"],
    iframe[src*="adservice"],
    iframe[src*="cookie-sync"],
    iframe[src*="user-sync"],
    iframe[src*="usersync"],
    iframe[src*="richaudience"],
    iframe[src*="rubiconproject"],
    iframe[src*="onetag-sys"],
    iframe[src*="presage.io"],
    
    /* Common banner sizes */
    [style*="width: 300px"][style*="height: 250px"],
    [style*="width: 728px"][style*="height: 90px"],
    [style*="width: 300px"][style*="height: 600px"],
    
    /* Cookie/consent walls - optional, comment out if unwanted */
    /* [class*="consent"], [id*="consent"], */
    
    /* Site-specific: Xataka */
    .c-branded, .c-branded-content,
    .opti-digital-slot,
    
    /* Generic "Publicidad" labels and their parents */
    [class*="advertisement"]
    
    { display: none !important; visibility: hidden !important; height: 0 !important; overflow: hidden !important; }
  `;
  document.head.appendChild(style);
  
  // Also block new ad scripts from loading
  const observer = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      for (const node of mutation.addedNodes) {
        if (node.tagName === 'IFRAME') {
          const src = node.src || '';
          if (/doubleclick|googlesyndication|amazon-adsystem|criteo|pubmatic|adnxs|2mdn\.net/.test(src)) {
            node.remove();
          }
        }
        if (node.tagName === 'SCRIPT') {
          const src = node.src || '';
          if (/pagead|adsbygoogle|googletag/.test(src)) {
            node.remove();
          }
        }
      }
    }
  });
  observer.observe(document.documentElement, { childList: true, subtree: true });
})();
