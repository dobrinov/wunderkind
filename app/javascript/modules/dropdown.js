import { computePosition, offset, flip, shift, autoUpdate } from '@floating-ui/dom';

document.addEventListener("DOMContentLoaded", () => {
  const dropdownTrigger = document.querySelector(".js-dropdown");

  if (dropdownTrigger) {
    const dropdownContainerTemplate = document.getElementById(dropdownTrigger.dataset.for);

    if (!dropdownContainerTemplate) {
      throw new Error(`Dropdown container not found: ${dropdownTrigger.dataset.for}`);
    }

    const fragment = dropdownContainerTemplate.content.cloneNode(true);
    const dropdownContainer = fragment.querySelector(".js-dropdown-container");
    let cleanup;

    function open() {
      document.body.appendChild(dropdownContainer);
      cleanup = autoUpdate(dropdownTrigger, dropdownContainer, updatePosition);
      updatePosition();
    }

    function close() {
      if (!dropdownContainer.isConnected) return;

      dropdownContainer.remove();
      if (cleanup) {
        cleanup();
        cleanup = undefined;
      }
    }

    function updatePosition() {
      computePosition(dropdownTrigger, dropdownContainer, {
        placement: 'bottom-end',
        middleware: [offset(8), flip(), shift()],
      }).then(({x, y}) => {
        Object.assign(dropdownContainer.style, {
          left: `${x}px`,
          top: `${y}px`,
        });
      });
    }

    function onClickOutside(e) {
      if (!dropdownContainer.contains(e.target) && !dropdownTrigger.contains(e.target)) {
        close();
      }
    }

    function onEscape(e) {
      if (e.key === 'Escape') {
        close();
      }
    }

    dropdownTrigger.addEventListener("click", () => {
      dropdownContainer.isConnected ? close() : open();
    });

    document.addEventListener('mousedown', onClickOutside);
    document.addEventListener('keydown', onEscape);
  }
})
