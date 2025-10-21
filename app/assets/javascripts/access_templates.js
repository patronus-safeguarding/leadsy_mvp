// Access Templates functionality
document.addEventListener('DOMContentLoaded', function() {
  // Select All functionality for provider scopes
  const selectAllButtons = document.querySelectorAll('.select-all-btn');
  const deselectAllButtons = document.querySelectorAll('.deselect-all-btn');
  
  selectAllButtons.forEach(button => {
    button.addEventListener('click', function() {
      const provider = this.getAttribute('data-provider');
      const checkboxes = document.querySelectorAll(`input[data-provider="${provider}"].scope-checkbox`);
      
      checkboxes.forEach(checkbox => {
        checkbox.checked = true;
      });
    });
  });
  
  deselectAllButtons.forEach(button => {
    button.addEventListener('click', function() {
      const provider = this.getAttribute('data-provider');
      const checkboxes = document.querySelectorAll(`input[data-provider="${provider}"].scope-checkbox`);
      
      checkboxes.forEach(checkbox => {
        checkbox.checked = false;
      });
    });
  });
});
