function setup()
{
	createCanvas(640,1136);
}
function draw() 
{
	background(255);
	rect(mouseX,mouseY,80,80);
}
	push();
	fill(100,100);
	rect(0,0,width,height);
	pop();
	ellipse(mouseX,mouseY,100,100);
}
