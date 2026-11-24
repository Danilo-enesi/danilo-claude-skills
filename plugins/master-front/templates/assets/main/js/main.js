/* Global front scripts: global helpers, plugin initialisation, generic listeners.
   A self-contained feature (map, auth, ...) goes in its own module file (map.js) instead. */

(function ($) {
  'use strict';

  /* Helpers
  ------------------------------------------------------------ */

  /** Front translation from window.front.translations ('front::group.key'), the key itself when missing. */
  window.trans = function (key) {
    var translations = window.front.translations || {};
    return translations[key] || key;
  };

  /* Init
  ------------------------------------------------------------ */

  $(function () {
  });
})(jQuery);
