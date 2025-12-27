window.MathJax = {
  tex: {
    inlineMath: [["\\(", "\\)"]],
    displayMath: [["\\[", "\\]"]],
    processEscapes: true,
    processEnvironments: true
  },
  options: {
    ignoreHtmlClass: ".*|",
    processHtmlClass: "arithmatex" // This tells MathJax to look inside the Arithmatex spans
  }
};

document.addEventListener("DOMContentLoaded", function() {
  // This ensures math is rendered on initial load
  if (typeof MathJax !== 'undefined') {
    MathJax.typesetPromise();
  }
});

// This is the "magic" for Material Theme's instant loading
// It re-runs MathJax every time you navigate to a new page
if (typeof document$ !== 'undefined') {
  document$.subscribe(function() {
    if (typeof MathJax !== 'undefined') {
      MathJax.typesetPromise();
    }
  });
}