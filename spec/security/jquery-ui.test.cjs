const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {JSDOM} = require('jsdom');
const root = process.env.JQUERY_UI_ROOT;
assert.ok(root, 'Set JQUERY_UI_ROOT to jquery-ui-rails/app/assets/javascripts/jquery-ui');
test('CVE-2022-31160: checkboxradio refresh keeps escaped label text inert', () => {
  const dom = new JSDOM('<label><input id="probe" type="checkbox">&lt;img src=x onerror="window.pwned=1"&gt;</label>', {runScripts:'dangerously'});
  const $ = require('jquery')(dom.window);
  dom.window.jQuery = $;
  for (const file of ['version.js', 'widget.js', 'form.js', 'form-reset-mixin.js', 'labels.js', 'widgets/checkboxradio.js']) {
    const source = path.join(root, file);
    if (file === 'form.js' && !fs.existsSync(source)) continue; // Removed by upstream jQuery UI 1.14.
    dom.window.eval(fs.readFileSync(source, 'utf8'));
  }
  $('#probe').checkboxradio().checkboxradio('refresh');
  assert.equal(dom.window.document.querySelectorAll('img').length, 0);
  assert.ok($('label').text().includes('<img src=x'));
});
