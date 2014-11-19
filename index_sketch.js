var audio
var peaks
var PEAKLENGTH = 100000
var bufferMax = 500
var first = true
var time = 0.0
var s = 2
function setup() {
	createCanvas(window.innerWidth, window.innerHeight)

	colorMode(HSB, 255)
	rectMode(CENTER)
	noStroke()
	audio = new p5.SoundFile('assets/aphex.mp3',playSound)
	//audio.play()
}

function playSound() {
	//var osc = new p5.Oscillator(440, 'sine')
	//osc.start()
	audio.play()
}

function drawLoad() {
	background(35);
	translate(window.innerWidth/2, window.innerHeight/2);
	for(var i = 0; i < 2*PI; i += radians(10))
	{
		fill(map((time + i + PI)%(PI*2), 0, 2 * PI, 0, 255), 200, 200);
		var w = map((i + PI)%(PI*2), 0, 2 * PI, 0, 100) * s;
		push();
		translate(s * 100 * cos(i + sin(time + i)),s * 100 * sin(i + sin(time + i)));
		rotate(i + sin(time + i));
		rect(0,0,w,5 * s,10);
		pop();
	}
	time += .07;
}

function draw() {
	if(audio.isLoaded() && first)
	{
		peaks = audio.getPeaks(PEAKLENGTH)
		first = false
	}
	else if(first)
	{
		drawLoad()
		return;
	}
	var amp = audio.getLevel()
	var uamp = map(amp,0,1,0,400)
	var ctime = ~~(audio.currentTime()/audio.duration() * PEAKLENGTH)

	background(uamp,100,100)
	translate(0,window.innerHeight/2)
	//text(ctime, 200,200)
	for (var i = 0; i < bufferMax; i++) {
		rect(map(i,0,bufferMax,0,window.innerWidth),map(peaks[i + ctime], 0, 1, 0,200),2,2)
	}
}

function keyPressed() {

}