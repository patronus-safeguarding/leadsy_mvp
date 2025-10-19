// Dashboard functionality
document.addEventListener('DOMContentLoaded', function() {
  // Tab switching functionality
  const tabItems = document.querySelectorAll('.tab-item[data-tab]');
  const tabPanels = document.querySelectorAll('.tab-panel[data-panel]');
  
  tabItems.forEach(tab => {
    tab.addEventListener('click', function() {
      const targetTab = this.getAttribute('data-tab');
      
      // Remove active class from all tabs and panels
      tabItems.forEach(t => t.classList.remove('active'));
      tabPanels.forEach(p => p.classList.remove('active'));
      
      // Add active class to clicked tab and corresponding panel
      this.classList.add('active');
      const targetPanel = document.querySelector(`[data-panel="${targetTab}"]`);
      if (targetPanel) {
        targetPanel.classList.add('active');
      }
    });
  });
  
  // Copy button functionality
  const copyButtons = document.querySelectorAll('.copy-button');
  copyButtons.forEach(button => {
    button.addEventListener('click', function() {
      const linkInput = this.closest('.link-container').querySelector('.link-input');
      linkInput.select();
      linkInput.setSelectionRange(0, 99999); // For mobile devices
      
      try {
        document.execCommand('copy');
        
        // Visual feedback
        const originalText = this.textContent;
        this.textContent = 'Copied!';
        this.style.background = '#10b981';
        
        setTimeout(() => {
          this.textContent = originalText;
          this.style.background = '#3b82f6';
        }, 2000);
      } catch (err) {
        console.error('Failed to copy text: ', err);
      }
    });
  });
  
      // Client selection functionality
      const clientSelect = document.querySelector('#client-select');
      if (clientSelect) {
        clientSelect.addEventListener('change', function() {
          const selectedClientId = this.value;
          if (selectedClientId) {
            // Reload the page with the selected client
            const url = new URL(window.location);
            url.searchParams.set('client_id', selectedClientId);
            // Remove generate_link parameter when switching clients
            url.searchParams.delete('generate_link');
            window.location.href = url.toString();
          }
        });
      }

      // Template selection functionality
      const templateSelect = document.querySelector('#template-select');
      if (templateSelect) {
        templateSelect.addEventListener('change', function() {
          const selectedTemplateId = this.value;
          if (selectedTemplateId) {
            // Reload the page with the selected template
            const url = new URL(window.location);
            url.searchParams.set('template_id', selectedTemplateId);
            // Remove generate_link parameter when switching templates
            url.searchParams.delete('generate_link');
            window.location.href = url.toString();
          }
        });
      }
  
  // Search functionality
  const searchInput = document.querySelector('.search-input');
  if (searchInput) {
    searchInput.addEventListener('input', function() {
      const searchTerm = this.value.toLowerCase();
      const tableRows = document.querySelectorAll('.clients-table tbody tr');
      
      tableRows.forEach(row => {
        const clientName = row.querySelector('.client-name').textContent.toLowerCase();
        if (clientName.includes(searchTerm)) {
          row.style.display = '';
        } else {
          row.style.display = 'none';
        }
      });
    });
  }
});
