(function(window) {
  window.env = window.env || {};
  
  // Environment variables for production
  window.env.apiUrl = 'http://localhost:8000/api';
  
  // Function to remove any text containing "OBIX" and "Admin" from the header
  function cleanHeader() {
    // Wait for DOM to be ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', executeClean);
    } else {
      executeClean();
    }
    
    function executeClean() {
      // Find all text nodes in the document
      const walker = document.createTreeWalker(
        document.body,
        NodeFilter.SHOW_TEXT,
        null,
        false
      );
      
      const textsToRemove = [];
      let node;
      
      // Collect text nodes containing "OBIX Admin"
      while (node = walker.nextNode()) {
        const text = node.nodeValue.trim();
        if (text.includes('OBIX Admin') || 
            (text.includes('OBIX') && text.includes('Admin'))) {
          textsToRemove.push(node);
        }
      }
      
      // Remove collected text nodes
      textsToRemove.forEach(node => {
        node.nodeValue = '';
      });
      
      // Also hide any elements specifically in headers
      const headers = document.querySelectorAll('.chat-header, header, .header, [class*="header"]');
      headers.forEach(header => {
        const children = header.childNodes;
        for (let i = 0; i < children.length; i++) {
          const child = children[i];
          if (child.nodeType === Node.TEXT_NODE) {
            child.nodeValue = '';
          } else if (child.nodeType === Node.ELEMENT_NODE) {
            if (child.tagName.toLowerCase() !== 'img' && 
                !child.querySelector('img') && 
                !child.classList.contains('user-controls') &&
                !child.classList.contains('logo-container')) {
              child.style.display = 'none';
            }
          }
        }
      });
      
      // Specifically target any fixed positioned elements that might contain the text
      const fixedElements = document.querySelectorAll('*[style*="fixed"]');
      fixedElements.forEach(el => {
        if (el.innerText && el.innerText.includes('OBIX Admin')) {
          const children = el.childNodes;
          for (let i = 0; i < children.length; i++) {
            const child = children[i];
            if (child.nodeType === Node.TEXT_NODE) {
              child.nodeValue = '';
            }
          }
        }
      });
    }
  }
  
  // Execute the function immediately and also on any subsequent DOM mutations
  cleanHeader();
  
  // Set up a MutationObserver to handle dynamic content
  const observer = new MutationObserver(cleanHeader);
  observer.observe(document.documentElement, { 
    childList: true, 
    subtree: true 
  });
  
})(window); 