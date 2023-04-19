const TEXT = [
  [
    "                         ",
    "                         ",
    "                         ",
    "                         ",
    "                         ",
    "                         ",
    "                         ",
    "                         ",
    "                         ",
  ],
  [
    "ww   ww  hh   hh  ooooooo",
    "ww   ww  hh   hh  ooooooo",
    "ww   ww  hh   hh  oo   oo",
    "ww w ww  hh   hh  oo   oo",
    "wwwwwww  hhhhhhh  oo   oo",
    "wwwwwww  hhhhhhh  oo   oo",
    "www www  hh   hh  oo   oo",
    "ww   ww  hh   hh  ooooooo",
    "w     w  hh   hh  ooooooo",
  ],
  [
    "   a     rrrrr    eeeeeee",
    "  aaa    rrrrrr   eeeeeee",
    " aa aa   rr   rr  ee     ",
    "aa   aa  rr  rrr  ee     ",
    "aaaaaaa  rrrrrr   eeeeeee",
    "aaaaaaa  rrrrrr   ee     ",
    "aa   aa  rr  rr   ee     ",
    "aa   aa  rr   rr  eeeeeee",
    "aa   aa  rr   rr  eeeeeee",
  ],
  [
    "yy   yy  ooooooo  uu   uu",
    "yy   yy  ooooooo  uu   uu",
    "yy   yy  oo   oo  uu   uu",
    "yy   yy  oo   oo  uu   uu",
    "yyyyyyy  oo   oo  uu   uu",
    "yyyyyyy  oo   oo  uu   uu",
    "  yyy    oo   oo  uu   uu",
    "  yyy    ooooooo  uuuuuuu",
    "  yyy    ooooooo  uuuuuuu",
  ],
];

const CHARS = 'abcdefghijklmnopqrstuvwxyz` ~!^*()_+-=[]{};:"\\|<>,./?';

const PERIOD_MS = 3000;
const PEAK_MS = PERIOD_MS / 2;
const START = Date.now() + PEAK_MS;

function blip(t) {
  return Math.exp(-(((t - PEAK_MS) / 800) ** 2)) ** 2;
}

function randomChar() {
  return CHARS[Math.floor(Math.random() * CHARS.length)];
}

function refresh() {
  const t = Date.now() - START;
  const scale = blip((t + PEAK_MS) % PERIOD_MS);
  const word = TEXT[Math.floor(((t / PERIOD_MS) % (TEXT.length - 1)) + 1)];
  const nodes = document.getElementsByClassName("row");

  for (let i = 0; i < word.length; i++) {
    const node = nodes[i];
    const row = word[i].split("");
    for (let c = 0; c < row.length; c++) {
      const offset = (node.innerText[c] === " ") + (row[c] === " ");
      if (Math.random() < scale - offset / 3) {
        row[c] = randomChar();
      }
    }

    node.innerText = row.join("");
  }
}

function main() {
  setInterval(refresh, 40);
}

main();
