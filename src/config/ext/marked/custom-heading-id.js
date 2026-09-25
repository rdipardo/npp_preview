/**
 * Minified by jsDelivr using Terser v5.39.0.
 * Original file: /npm/marked-custom-heading-id@2.0.17/lib/index.umd.js
 *
 * Do NOT use SRI with dynamically generated files! More information: https://www.jsdelivr.com/using-sri-with-dynamic-files
 */
!function(e,n){"object"==typeof exports&&"undefined"!=typeof module?module.exports=n():"function"==typeof define&&define.amd?define(n):(e="undefined"!=typeof globalThis?globalThis:e||self).markedCustomHeadingId=n()}(this,(function(){"use strict";return function(){return{useNewRenderer:!0,renderer:{heading(e,n){"string"!=typeof e&&(n=e.depth,e=e.text);const t=/(?: +|^)\{#([a-z][\w-]*)\}(?: +|$)/i,d=e.match(t);return!!d&&`<h${n} id="${d[1]}">${e.replace(t,"")}</h${n}>\n`}}}}}));
//# sourceMappingURL=/sm/b128a02d2fbfd8f3cf1ef053e6bb5d83eb30b24676d6036abb999bb2498eec4e.map