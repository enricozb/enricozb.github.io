var audio = new buzz.sound("assets/aphex.mp3");

function setup() {
	createCanvas(window.innerWidth, window.innerHeight)
	//var audio = loadSound('assets/aphex.mp3')
	audio.play();
	//osc.start()
}

function draw() {
	ellipse(pwinMouseX,pwinMouseY,50,50)
}

function keyPressed() {

}