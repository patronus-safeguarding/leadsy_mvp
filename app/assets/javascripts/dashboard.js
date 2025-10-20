// Dashboard interactions for generating access links
(function() {
  document.addEventListener('DOMContentLoaded', function() {
    if (!document.querySelector('.simplified-dashboard')) return;
    setupFormHandlers();
    setupTabs();
    setupSelectionNavigation();
  });

  function setupTabs() {
    var tabNav = document.querySelector('.tab-nav');
    if (!tabNav) return;
    tabNav.addEventListener('click', function(e) {
      var tab = e.target.closest('.tab-item');
      if (!tab) return;
      var target = tab.getAttribute('data-tab');
      if (!target) return;
      // toggle active state on tabs
      document.querySelectorAll('.tab-item').forEach(function(t) {
        t.classList.toggle('active', t === tab);
      });
      // toggle active state on panels
      document.querySelectorAll('.tab-panel').forEach(function(panel) {
        var isTarget = panel.getAttribute('data-panel') === target;
        panel.classList.toggle('active', isTarget);
      });
    });
  }

  function setupSelectionNavigation() {
    var clientSelect = document.getElementById('client-select');
    var templateSelect = document.getElementById('template-select');

    function navigate() {
      var clientId = clientSelect && clientSelect.value ? clientSelect.value : null;
      var templateId = templateSelect && templateSelect.value ? templateSelect.value : null;
      var url = new URL(window.location.href);
      url.pathname = '/dashboard';
      if (clientId) { url.searchParams.set('client_id', clientId); } else { url.searchParams.delete('client_id'); }
      if (templateId) { url.searchParams.set('template_id', templateId); } else { url.searchParams.delete('template_id'); }
      window.location.assign(url.toString());
    }

    if (clientSelect) {
      clientSelect.addEventListener('change', function() {
        hideGeneratedLink();
        navigate();
      });
    }
    if (templateSelect) {
      templateSelect.addEventListener('change', function() {
        hideGeneratedLink();
        navigate();
      });
    }
  }

  window.showGeneratedLink = function(link) {
    var linkSection = document.getElementById('generated-link-section');
    var generateSection = document.getElementById('generate-link-section');
    var linkInput = document.getElementById('generated-link-input');
    if (!linkSection || !generateSection || !linkInput) return;
    linkInput.value = link;
    linkSection.style.display = 'block';
    generateSection.style.display = 'none';
  };

  window.hideGeneratedLink = function() {
    var linkSection = document.getElementById('generated-link-section');
    var generateSection = document.getElementById('generate-link-section');
    if (!linkSection || !generateSection) return;
    linkSection.style.display = 'none';
    generateSection.style.display = 'block';
  };

  window.copyGeneratedLink = function() {
    var linkInput = document.getElementById('generated-link-input');
    if (!linkInput) return;
    var link = linkInput.value;
    navigator.clipboard.writeText(link)
      .then(function() { if (window.event && window.event.target) showCopyFeedback(window.event.target); })
      .catch(function(err) {
        console.error('Could not copy text: ', err);
        var textArea = document.createElement('textarea');
        textArea.value = link;
        document.body.appendChild(textArea);
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);
        if (window.event && window.event.target) showCopyFeedback(window.event.target);
      });
  };

  window.openGeneratedLink = function() {
    var linkInput = document.getElementById('generated-link-input');
    if (!linkInput) return;
    var link = linkInput.value;
    window.open(link, '_blank');
  };

  window.showCopyFeedback = function(button) {
    if (!button) return;
    var originalText = button.textContent;
    button.textContent = 'Copied!';
    button.style.background = '#10b981';
    setTimeout(function() {
      button.textContent = originalText;
      button.style.background = '';
    }, 2000);
  };

  function setupFormHandlers() {
    var generateButton = document.querySelector('.generate-link-btn');
    if (generateButton) {
      generateButton.addEventListener('click', function(e) {
        e.preventDefault();
        var clientSelect = document.getElementById('client-select');
        var templateSelect = document.getElementById('template-select');
        if (!clientSelect || !templateSelect || !clientSelect.value || !templateSelect.value) {
          alert('Please select both a client and a template');
          return;
        }
        var originalText = this.value;
        this.value = 'Generating...';
        this.disabled = true;
        var formData = new FormData();
        formData.append('client_id', clientSelect.value);
        formData.append('template_id', templateSelect.value);
        formData.append('authenticity_token', document.querySelector('meta[name="csrf-token"]').content);
        fetch('/dashboard', {
          method: 'POST',
          body: formData,
          headers: { 'Accept': 'application/json', 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content }
        })
        .then(function(response) { return response.json(); })
        .then(function(data) {
          if (data.success && data.link) { showGeneratedLink(data.link); }
          else { console.error('Failed to generate link:', data); }
          generateButton.value = originalText;
          generateButton.disabled = false;
        })
        .catch(function(error) {
          console.error('Error generating link:', error);
          generateButton.value = originalText;
          generateButton.disabled = false;
        });
      });
    }
  }
})();
