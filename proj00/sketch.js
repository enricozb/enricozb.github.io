function setup()
{
	createCanvas(640,1136);
}
function draw() 
{
	push();
	fill(100,100);
	rect(0,0,width,height);
	pop();
	ellipse(mouseX,mouseY,100,100);
}
