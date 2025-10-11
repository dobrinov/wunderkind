import "./controllers"
import { computePosition, offset, flip, shift } from '@floating-ui/dom';

document.addEventListener("DOMContentLoaded", () => {
  const dropdownTrigger = document.querySelector(".js-dropdown");
  const dropdownContainerTemplate = document.getElementById(dropdownTrigger.dataset.for);

  if (!dropdownContainerTemplate) {
    throw new Error(`Dropdown container not found: ${dropdownTrigger.dataset.for}`);
  }

  if (dropdownTrigger) {
    const fragment = dropdownContainerTemplate.content.cloneNode(true);
    const dropdownContainer = fragment.querySelector(".js-dropdown-container");

    dropdownTrigger.addEventListener("click", () => {
      if(dropdownContainer.isConnected) {
        dropdownContainer.remove();
      } else {
        document.body.appendChild(dropdownContainer);

        computePosition(dropdownTrigger, dropdownContainer, {
          placement: 'bottom-end',
          middleware: [offset(8), flip(), shift()],
        }).then(({x, y}) => {
          Object.assign(dropdownContainer.style, {
            left: `${x}px`,
            top: `${y}px`,
          });
        })
      }
    })
  }
});
