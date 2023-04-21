const clicks = [];

let r = 0.0;
let gap = 0.0;
let count = 0;
let lastPressed = false;

let elapTime = 0.0;
let speed = 0.0;

function setup() {
  r = 20;
  gap = r / 2;
  elapTime = 0;
  speed = 0.05;
  noStroke();
  smooth(8);
  colorMode(HSB);
  fill(255);
  createCanvas(400, 400);
  background(0);
  noCursor();
}

function draw() {
  background(35);
  fill(255);

  if ((mouseIsPressed && !lastPressed) || (mouseIsPressed && count % 10 == 0)) {
    count++;
    lastPressed = true;
    clicks.push([mouseX, mouseY, 0]);
  } else if (mouseIsPressed) {
    count++;
  } else if (!mouseIsPressed) {
    count = 0;
    lastPressed = false;
  }

  for (let y = gap + r; y < height; y += 2 * r + gap) {
    for (let x = gap + r; x < width; x += 2 * r + gap) {
      let tempR = 0.0;
      for (const gr of clicks) {
        let rt = 0.0;
        rt = val(x, y, gr[0], gr[1], (gr[2] += speed));
        if (rt < 0) rt = 0;
        tempR += rt;
        if (tempR >= 3 * r) {
          tempR = 3 * r;
          break;
        }
      }
      fill(255 - (tempR / (3 * r)) * 255, 255, 255);
      ellipse(x, y, tempR, tempR);
    }
  }

  for (let i = 0; i < clicks.length; i++) {
    if (clicks[i][2] > 1800) {
      clicks.splice(i, 1);
      i--;
    }
  }
}

function val(x, y, lastX, lastY, eTime) {
  let tmpD = dist(x, y, 0, lastX, lastY, 0);
  return 2 * r - ((3 * abs(tmpD - eTime)) / tmpD) * r;
}
