export function renderQueue(queueContainer, queue) {
  if (!queueContainer) return;
  queueContainer.innerHTML = "";
  for (const q of queue) {
    const block = document.createElement("div");
    block.className = `queue-block ${q}`;
    queueContainer.appendChild(block);
  }
}
