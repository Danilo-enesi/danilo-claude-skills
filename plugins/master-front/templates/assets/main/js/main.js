/* Front scripts: global helpers, plugin initialisation, generic listeners and the logic of the front pages
   (one section per page, run only when the page is there). Only a complex, self-contained feature
   (ecommerce, a map with markers and filters...) goes in its own module file (map.js). */

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
