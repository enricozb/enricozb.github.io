const KEYS = [1, 2, 3, 4];
const TRANSMUTERS = [];
const LETTERS = "abcdefghijklmnopqrstuvwxyz";
const CODES = Object.fromEntries(Object.entries(LETTERS).map(([i, c]) => [c, Number(i)]));

class RNG {
  constructor(seed) {
    this.m = 0x80000000;
    this.a = 1103515245;
    this.c = 12345;

    this.state = seed ? seed : Math.floor(Math.random() * (this.m - 1));
  }

  nextInt() {
    this.state = (this.a * this.state + this.c) % this.m;

    return this.state;
  }

  nextFloat() {
    return this.nextInt() / (this.m - 1);
  }
}

function cipher_from_seed(seed) {
  const permuted = LETTERS.split("");
  shuffle(permuted, seed);

  const cipher = {};
  for (let i = 0; i < LETTERS.length; i++) {
    cipher[LETTERS[i]] = permuted[i];

    if (permuted[i] === undefined) {
      console.log(i, seed, LETTERS, permuted);
    }
  }

  return cipher;
}

function shuffle(array, seed) {
  const rng = new RNG(seed);

  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(rng.nextFloat() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
}

class Transmute {
  constructor(el) {
    this.el = el;
    this.text = el.innerText;
    this.mutated = this.text.split("");
  }

  transmute(uncipher) {
    if (this.timer) {
      clearInterval(this.timer);
    }

    const chars = [...Array(this.text.length).keys()];
    shuffle(chars);

    this.timer = setInterval(() => {
      for (const _ of Array(Math.ceil(this.text.length / 15))) {
        if (chars.length === 0) {
          clearInterval(this.timer);

          return;
        }

        const i = chars.pop();

        if (this.text[i].toLowerCase() in uncipher) {
          const isUpper = this.text[i].toUpperCase() === this.text[i];

          this.mutated[i] = isUpper
            ? uncipher[this.text[i].toLowerCase()].toUpperCase()
            : uncipher[this.text[i].toLowerCase()];
        }

        this.el.innerText = this.mutated.join("");
      }
    }, 50);
  }
}

function encrypt(text) {
  const key = [...KEYS];
  const seed = key[0] + key[1] * (26 ** 1) + key[2] * (26 ** 2) + key[3] * (26 ** 3);
  const cipher = cipher_from_seed(seed);

  let encrypted = [];
  for (const c of text) {
    if (c.toLowerCase() in cipher) {
      const isUpper = c.toUpperCase() === c;

      encrypted.push(isUpper ? cipher[c.toLowerCase()].toUpperCase() : cipher[c]);
    } else {
      encrypted.push(c);
    }
  }

  return encrypted.join("");
}

function attach() {
  for (const el of document.querySelectorAll("[secret]")) {
    TRANSMUTERS.push(new Transmute(el));
  }

  for (const el of document.querySelectorAll("[secret-text] p")) {
    TRANSMUTERS.push(new Transmute(el));
  }
}

function listen() {
  window.addEventListener("keydown", (e) => {
    KEYS.push(e.keyCode);

    if (KEYS.length > 4) {
      if (new Set(KEYS).size === 1) {
        KEYS[3] = KEYS[0] + 1;
      }

      KEYS.shift();
    }

    const key = [...KEYS];
    const seed = KEYS[0] + KEYS[1] * (26 ** 1) + KEYS[2] * (26 ** 2) + KEYS[3] * (26 ** 3);
    const cipher = cipher_from_seed(seed);
    const uncipher = Object.fromEntries(Object.entries(cipher).map(([a, b]) => [b, a]));

    for (const t of TRANSMUTERS) {
      t.transmute(uncipher);
    }
  });
}

function init() {
  attach();
  listen();
}

init();
