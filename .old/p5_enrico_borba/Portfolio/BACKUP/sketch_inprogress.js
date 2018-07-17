var offSet = 100
var tdelay = 1
var ispeed = 2
var fspeed = -2
var mspeed =  1
var mouse = false
var tsize = 40
var stratification = 30

var points = []

var width = 0
var height = 0

var fCount = 0

function setup() {
	createCanvas(window.innerWidth, window.innerHeight)
	colorMode(HSB)
	noStroke()
	width = window.innerWidth
	height = window.innerHeight
}

function draw() {
	fCount+=1
	background(0)
	fill(0,200,200)
	translate(width/2,height/2)
	if(points.length > offSet) {
		points.shift()
	}
	var arrayLength = points.length
	for(var i = 0; i < arrayLength; i++) {
		var point = points[i]
		fill(hueVal(i) % 255,200,200)
		ellipse(point[0], point[1], 20,20)
	}
	if(fCount % tdelay == 0) {
		points.push([x(),y()])
	}
}

function x() {
	return mouse ? (mouseX - width/2) : width/3 * cos(fCount/50.0 * mspeed)
}

function y() {
	return mouse ? (mouseY - height/2) : height/6 * sin(fCount/12.5 * mspeed)
}

function hueVal(i) {
	return (abs(fCount * fspeed + i * ispeed)/stratification|0) * stratification
}