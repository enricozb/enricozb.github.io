let shapes = [];
let dampening = 0.1;
let mLastPressX = -1;
let mLastPressY = -1;
const speed = 3;
let userInteractive = true;

function setup() {
  createCanvas(500, 500);
  colorMode(HSB);
  noStroke();
  smooth(12);

  let vTemp = [
    [100, 100],
    [100, 400],
    [400, 400],
    [400, 100],
  ];

  let q = new Shape(vTemp, 0.0, 0);
  shapes.push(q);
}

function draw() {
  background(35);
  fill(0);

  for (let i = 0; i < shapes.length; i++) {
    shapes[i].updraw();

    if (shapes[i].gArea() < 20) {
      shapes.splice(i, 1);
      i--;
    }
  }

  if (userInteractive) {
    if (!mouseIsPressed && mLastPressX == -1 && mLastPressY == -1) {
      mLastPressX = -1;
      mLastPressY = -1;
    } else if (mLastPressX == -1 && mLastPressY == -1) {
      mLastPressX = mouseX;
      mLastPressY = mouseY;
    } else if (mouseIsPressed) {
      stroke(0, 255, 255);
      strokeWeight(1);
      line(mLastPressX, mLastPressY, mouseX, mouseY);
      noStroke();
    } else {
      slice(mouseX, mouseY);
      mLastPressX = -1;
      mLastPressY = -1;
    }
  } else {
    mLastPressX = random(0, width);
    mLastPressY = random(0, height);
    let xTemp = random(0, width);
    let yTemp = random(0, height);
    slice(xTemp, yTemp);
  }
}

function slice(x, y) {
  let temp = shapes.slice();

  for (let q of shapes) {
    let temp2 = [];

    try {
      temp2 = q.slice(x, y);
    } catch (e) {}

    if (temp2 != null && temp2.length != 0) {
      temp = temp.concat(temp2);
      temp.splice(temp.indexOf(q), 1);
    }
  }

  shapes = temp;
}

function keyPressed() {
  if (key === "p") {
    userInteractive = false;
  }
}

class Shape {
  constructor(vertexes, degree, magnitude) {
    this.vertexes = vertexes;
    this.degree = degree;
    this.magnitude = magnitude;
    this.col = random(0, 255);
  }

  updraw() {
    fill(this.col, 200, 200);
    beginShape();
    for (let v of this.vertexes) {
      vertex(v[0], v[1]);
    }
    endShape();
    noFill();
    this.update();
  }

  update() {
    let xTransform = this.magnitude * cos(this.degree);
    let yTransform = this.magnitude * sin(this.degree);
    for (let v of this.vertexes) {
      v[0] += xTransform;
      v[1] += yTransform;
    }
    this.magnitude = max(0, this.magnitude - dampening);
  }

  gArea() {
    let tempA = 0;
    for (let i = 0; i < this.vertexes.length - 1; i++) {
      tempA += abs(this.vertexes[i][0] - this.vertexes[i + 1][0]);
      tempA += abs(this.vertexes[i][1] - this.vertexes[i + 1][1]);
    }
    tempA +=
      abs(this.vertexes[this.vertexes.length - 1][0] - this.vertexes[0][0]) +
      abs(this.vertexes[this.vertexes.length - 1][1] - this.vertexes[0][1]);
    return tempA / 2;
  }

  slice(x, y) {
    let tempQ = [];
    let m = this.vertexes.length;
    let pts = new Array(m).fill().map(() => new Array(2));
    for (let i = 0; i < m; i++) {
      pts[i][0] = this.vertexes[i][0];
      pts[i][1] = this.vertexes[i][1];
    }
    let pTemp = [];
    let i = 0;
    while (
      this.intersect(
        pts[i][0],
        pts[i][1],
        pts[(i + 1) % m][0],
        pts[(i + 1) % m][1],
        mLastPressX,
        mLastPressY,
        x,
        y
      ) == null
    ) {
      i++;
      if (i == m) return null;
    }
    pTemp.push(
      this.intersect(
        pts[i][0],
        pts[i][1],
        pts[(i + 1) % m][0],
        pts[(i + 1) % m][1],
        mLastPressX,
        mLastPressY,
        x,
        y
      )
    );
    i++;
    i %= m;
    while (
      this.intersect(
        pts[i][0],
        pts[i][1],
        pts[(i + 1) % m][0],
        pts[(i + 1) % m][1],
        mLastPressX,
        mLastPressY,
        x,
        y
      ) == null
    ) {
      i %= m;
      pTemp.push(pts[i]);
      i++;
    }
    pTemp.push(pts[i]);
    pTemp.push(
      this.intersect(
        pts[i][0],
        pts[i][1],
        pts[(i + 1) % m][0],
        pts[(i + 1) % m][1],
        mLastPressX,
        mLastPressY,
        x,
        y
      )
    );
    tempQ.push(
      new Shape(pTemp, atan((y - mLastPressY) / (x - mLastPressX)), speed)
    );
    pTemp = [];
    pTemp.push(
      this.intersect(
        pts[i][0],
        pts[i][1],
        pts[(i + 1) % m][0],
        pts[(i + 1) % m][1],
        mLastPressX,
        mLastPressY,
        x,
        y
      )
    );
    i++;
    i %= m;
    while (
      this.intersect(
        pts[i][0],
        pts[i][1],
        pts[(i + 1) % m][0],
        pts[(i + 1) % m][1],
        mLastPressX,
        mLastPressY,
        x,
        y
      ) == null
    ) {
      pTemp.push(pts[i]);
      i++;
      i %= m;
    }
    pTemp.push(pts[i]);
    pTemp.push(
      this.intersect(
        pts[i][0],
        pts[i][1],
        pts[(i + 1) % m][0],
        pts[(i + 1) % m][1],
        mLastPressX,
        mLastPressY,
        x,
        y
      )
    );

    tempQ.push(
      new Shape(pTemp, atan((y - mLastPressY) / (x - mLastPressX)) + PI, speed)
    );

    return tempQ;
  }

  intersect(x1, y1, x2, y2, x3, y3, x4, y4) {
    let bx = x2 - x1;
    let by = y2 - y1;
    let dx = x4 - x3;
    let dy = y4 - y3;
    let b_dot_d_perp = bx * dy - by * dx;

    if (b_dot_d_perp == 0) {
      return null;
    }

    let cx = x3 - x1;
    let cy = y3 - y1;
    let t = (cx * dy - cy * dx) / b_dot_d_perp;

    if (t < 0 || t > 1) {
      return null;
    }

    let u = (cx * by - cy * bx) / b_dot_d_perp;

    if (u < 0 || u > 1) {
      return null;
    }

    return [x1 + t * bx, y1 + t * by];
  }
}
