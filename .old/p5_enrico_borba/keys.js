function load(path) {
	document.location.href = path
}

Mousetrap.bind('t', function() {load('timer/index.html')})
Mousetrap.bind('o', function() {load('p5/oscilloscope/index.html')})