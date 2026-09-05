// Sharing is user-initiated. No analytics, SDKs, or background requests.
const copyButton = document.getElementById('copy-share');
const shareMessage = document.getElementById('share-message');
const shareStatus = document.getElementById('share-status');
if (copyButton && shareMessage && shareStatus && navigator.clipboard?.writeText) {
  copyButton.hidden = false;
  copyButton.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(shareMessage.textContent.trim());
      shareStatus.textContent = 'Copied! Paste it into a message or post and make it yours.';
    } catch {
      shareStatus.textContent = 'Copy was blocked. Select the message above and copy it, or use a sharing link.';
    }
  });
}
