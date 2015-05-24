var DIAMETER = 7
var NUM = 50
var MAX_DIST = 100
var SPEED = 0.4

var parr = []

function setup() {
	devicePixelScaling(2)
	createCanvas(windowWidth, windowHeight)
	fill(60)
	stroke(60)
	for(var i = 0; i < NUM; i++) {
		parr.push(new Pt(false))
	}
}

function draw() {
	background(25)
	var l = parr.length
	for(var i = l - 1; i >= 0; i--) {
		var p = parr[i]
		p.draw()
		p.update()
		for(var j = l - 1; j >= 0; j--) {
			var q = parr[j]
			if(q === p) {
				continue;
			}
			var d = q.p.dist(p.p)
			if(d < MAX_DIST){
				push()
				strokeWeight(map(d, 0, MAX_DIST, 1, 0))
				line(q.p.x, q.p.y, p.p.x, p.p.y)
				pop()
			}
		}
		if(p.out()) {
			parr.splice(i, 1)
			parr.push(new Pt(true))
		}

	}
}

function Pt(walled) {
	this.p = randp(walled)
	this.v = randv()
	this.draw = function() {
		ellipse(this.p.x, this.p.y, DIAMETER, DIAMETER)
	}
	this.update = function() {
		this.p.add(this.v)
	}
	this.out = function() {
		return (this.p.x - 2 * DIAMETER > windowWidth || this.p.x + 2 * DIAMETER < 0 || this.p.y - 2 * DIAMETER > windowHeight || this.p.y + 2 * DIAMETER < 0);
	}
}

function randp(walled) {
	if(!walled)
		return createVector(random(windowWidth), random(windowHeight))
	var w = Math.floor(random(4))
	switch(w) {
		case 0: return createVector(-DIAMETER, random(windowHeight));
		case 1: return createVector(random(windowWidth), -DIAMETER);
		case 2: return createVector(windowWidth + DIAMETER, random(windowHeight));
		case 3: return createVector(random(windowWidth), windowHeight + DIAMETER);
	}
}

function randv() {
	return createVector(random(-SPEED, SPEED), random(-SPEED, SPEED))
}