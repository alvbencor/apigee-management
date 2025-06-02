// Toggle del sidebar
const toggleBtn = document.getElementById('toggle');
const app = document.getElementById('app');

if (toggleBtn) {
  toggleBtn.addEventListener('click', () => {
    app.classList.toggle('expanded');
  });
}
