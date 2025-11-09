function normalize_text (t) {
  return (t
    .toLowerCase()
    // remove the punctuation used in the main translation (summary) and the terms
    .replace(/[\u0640\u064B-\u065F]+/g, '')
    .replace(/[-\u2013_\s,،.:;؛(){}\[\]«»\u2E28\u2E29]+/g, ' ')
    .replace(/^ /g, '').replace(/ $/g, ' ')
    )
}
function filter_terms (q) {
  var tocens = document.querySelectorAll('.toc > a')
  /***before*loop***/
  for (var i = 0; i < tocens.length; ++i) {
    var a = tocens[i]
    var nq = normalize_text(q)
    a.className
     = normalize_text(a.textContent).indexOf(nq) === -1
    && normalize_text(a.title).indexOf(nq) === -1
    && normalize_text(a.dataset.spell).indexOf(nq) === -1
        ? 'hidden'
        : ''
    /***end*of*loop***/
  }
  /***after*loop***/
}
// redirect on nonpermalinks (eg, /#term) that aren't in this page
const tl = {
  /***term*links***/
}
function goto_link () {
  const lnk = tl[location.hash.toLowerCase()]  // a term starts with '#'; tl only has terms that aren't in this page
  if (lnk) { location.href = lnk }  // redirect to the correct page and part of page
}
onload = function () {
  var f = document.getElementById('toc_filter')
  f.oninput = function () { filter_terms(this.value) }
  document.getElementById('sub').onsubmit = function () { filter_terms(f.value) }
  if (location.search) {
    const vals = location.search.split(/[?&]/).filter(kv => kv.startsWith('q='))
    if (vals.length) { f.value = decodeURI(vals[0].split('=')[1]) }
  }
  if (f.value) { filter_terms(f.value) }
  goto_link()
}
onhashchange = goto_link
