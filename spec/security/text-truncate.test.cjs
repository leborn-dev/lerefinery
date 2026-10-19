const {test} = require('node:test');
const assert = require('node:assert/strict');
const {JSDOM} = require('jsdom');
const fs = require('node:fs');
const path = require('node:path');
function setup(text, width, tail = '&hellip;') {
  const dom = new JSDOM('<div><span id="target"></span></div>', {runScripts: 'dangerously'});
  const $ = require('jquery')(dom.window);
  dom.window.jQuery = $;
  dom.window.eval(fs.readFileSync(path.join(__dirname, '../../core/vendor/assets/javascripts/jquery/jquery.textTruncate.js'), 'utf8'));
  // jsdom has no layout: use deterministic glyph widths, retaining real DOM parsing.
  $.fn.width = function() { return this[0]?.tagName === 'TD' ? this.text().length * 10 : width; };
  const element = $('#target').text(text);
  element.textTruncate(dom.window.Object.assign(new dom.window.Object(), {width, tail}));
  return {dom, element};
}
test('literal HTML in fitting text remains text, never executable DOM', () => {
  const text = '<img src=x onerror="window.pwned=1">';
  const {dom, element} = setup(text, 2000);
  assert.equal(element.find('img').length, 0);
  assert.equal(element.text(), text);
  assert.equal(dom.window.pwned, undefined);
});
test('truncated text preserves literal ampersands and angle brackets and trusted HTML tail', () => {
  const {element} = setup('&&& << hello longer text', 180, '<a href="#more">more</a>');
  assert.equal(element.find('a').attr('href'), '#more');
  assert.ok(element.text().startsWith('&&& <<'));
  assert.equal(element.attr('title'), '&&& << hello longer text');
  assert.equal(element.find('img, script').length, 0);
});
test('a tail wider than the container terminates and still renders its link', () => {
  const {element} = setup('a long value', 10, '<a href="#more">more</a>');
  assert.equal(element.text(), 'more');
});
