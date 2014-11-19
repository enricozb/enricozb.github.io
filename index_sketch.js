var audio
var peaks
var PEAKLENGTH = 100000
var bufferMax = 500
function preload() {
	audio = loadSound('assets/aphex.mp3')
}

function setup() {
	createCanvas(window.innerWidth, window.innerHeight)

	colorMode(HSB, 255)
	rectMode(CENTER)
	noStroke()

	audio.play()
	peaks = audio.getPeaks(PEAKLENGTH)
}

function draw() {
	var amp = audio.getLevel()
	var uamp = map(amp,0,1,0,400)
	var ctime = ~~(audio.currentTime()/audio.duration() * PEAKLENGTH)

	background(uamp,100,100)
	translate(0,window.innerHeight/2)
	rect(window.innerWidth/2,0,window.innerHeight,10)
	//text(ctime, 200,200)
	for (var i = 0; i < bufferMax; i++) {
		rect(map(i,0,bufferMax,0,window.innerWidth),map(peaks[i + ctime], 0, 1, 0,200),2,2)
	}
}

function keyPressed() {

}