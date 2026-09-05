// Exercise both Clipboard outcomes and the no-API progressive fallback.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(require('node:path').join(__dirname, '../share.js'), 'utf8');
async function run(clipboard, expected) {
  let handler;
  const elements = {
    'copy-share': {hidden: true, addEventListener: (event, callback) => {assert.equal(event, 'click'); handler = callback;}},
    'share-message': {textContent: ' Share Cut & Move v1.0.2 https://example.com/ '},
    'share-status': {textContent: ''},
  };
  vm.runInNewContext(source, {document: {getElementById: id => elements[id]}, navigator: {clipboard}});
  if (!clipboard) {
    assert.equal(elements['copy-share'].hidden, true);
    assert.equal(handler, undefined);
  } else {
    assert.equal(elements['copy-share'].hidden, false);
    await handler();
    assert.match(elements['share-status'].textContent, expected);
  }
}
(async () => {
  await run({writeText: async text => assert.equal(text, 'Share Cut & Move v1.0.2 https://example.com/')}, /^Copied!/);
  await run({writeText: async () => {throw new Error('Denied');}}, /Copy was blocked/);
  await run(undefined);
  console.log('Sharing success, denied permission, and unsupported browser checks passed.');
})().catch(error => {console.error(error); process.exitCode = 1;});
