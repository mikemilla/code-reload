import {Linking} from 'react-native';

/// Metro's default welcome screen calls `openURLInBrowser`, which POSTs to the
/// dev server so URLs open on your Mac. On a physical device that fetch fails
/// ("promise failed"). Redirect to Linking so taps open Safari on the phone.
function patchOpenURLInBrowser() {
  try {
    const mod = require('react-native/Libraries/Core/Devtools/openURLInBrowser');
    const current = mod?.default;
    if (!current || current.__bunbuPatched) {
      return;
    }
    mod.default = function bunbuOpenURLInBrowser(url: string) {
      Linking.openURL(url).catch(() => {});
    };
    mod.default.__bunbuPatched = true;
  } catch {
    // DevTools module unavailable — ignore.
  }
}

patchOpenURLInBrowser();
