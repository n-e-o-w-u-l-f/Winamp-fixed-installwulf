document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.reveal').forEach((element) => {
    element.classList.add('js-ready');
  });

  const reveal = new IntersectionObserver((entries, observer) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12 });

  document.querySelectorAll('.reveal').forEach((element) => reveal.observe(element));

  const parallaxElements = document.querySelectorAll('.parallax');
  const updateParallax = () => {
    const y = window.scrollY || 0;
    parallaxElements.forEach((element) => {
      element.style.transform = `translate3d(0, ${y * 0.08}px, 0)`;
    });
  };

  window.addEventListener('scroll', updateParallax, { passive: true });
  updateParallax();
});
