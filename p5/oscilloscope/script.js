function setup() {
	createCanvas(windowWidth, windowHeight)
	background(25)
	stroke(0, 200, 0)
	fill(0, 200, 0)
}

var r = 1.1

function Point(scale) {
	this.scale = scale
	this.x = function(t) {
		return scale * sin(t)
	}

	this.y = function(t) {
		return scale * cos(r * t)
	}

	this.draw = function(t) {
		ellipse(this.x(t), this.y(t), 5, 5)
	}
}

var pt = new Point(300)
var time = 0.0

var rate = 0.1

function keyPressed() {
	r += .1
}

function draw() {
	translate(windowWidth/2, windowHeight/2)
	line(pt.x(time), pt.y(time), pt.x(time + rate), pt.y(time + rate))
	time += rate
}