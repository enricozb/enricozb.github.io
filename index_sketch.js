var audio
var peaks

var PADDING
var PEAKLENGTH
var SCALE
var bufferMax
var doneLoading
var time
var s

function setup() {
	createCanvas(window.innerWidth, window.innerHeight)

	colorMode(HSB, 255)
	rectMode(CENTER)
	stroke(127.5,100,200)

	PADDING = window.innerWidth/10
	PEAKLENGTH = 1000000
	SCALE = window.innerHeight/7
	bufferMax = 100
	doneLoading = false
	time = 0.0
	s = 2

	audio = new p5.SoundFile('https://github.com/enricozb/enricozb.github.io/blob/master/assets/flim.mp3',play)
}

function play() {
	audio.play()
	peaks = audio.getPeaks(PEAKLENGTH)
	doneLoading = true
}

function drawLoad() {
	background(0,100,100)
	translate(0,window.innerHeight/2)
	line(PADDING, 0, PADDING + time, 0)
	time += 10;
}

function draw() {
	if(!doneLoading)
	{
		drawLoad()
		return;
	}
	var amp = audio.getLevel()
	var uamp = map(amp,0,1,0,100)
	var ctime = ~~(audio.currentTime()/audio.duration() * PEAKLENGTH)
	background(uamp,100,100)
	translate(0,window.innerHeight/2)
	beginShape()
	for (var i = 0; i < bufferMax; i++) {
		stroke(abs(map(peaks[i + ctime], 0, 1, 0,400)) + 127.5,100,200)
		if(i == 0 || i == bufferMax - 1)
			curveVertex(map(i,0,bufferMax,PADDING,window.innerWidth-PADDING),map(peaks[i + ctime], 0, 1, 0,SCALE))
		curveVertex(map(i,0,bufferMax,PADDING,window.innerWidth-PADDING),map(peaks[i + ctime], 0, 1, 0,SCALE))
	}
	endShape()
}
