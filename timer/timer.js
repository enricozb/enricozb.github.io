var HOLD_TIME = 500

var hold_timer = new Tock({
	countdown: true,
	interval: 10,
	complete: endHold
})

var cube_timer = new Tock({
  interval: 10,
  callback: update,
});

function startTimer() {
	cube_timer.start()
}

function stopTimer() {
	cube_timer.stop()
}

function update() {
	var elapsed = cube_timer.lap();
	var sec = Math.floor(elapsed/1000)
	var rem = elapsed % 1000
	var rem_s = rem.toString()
	var length = rem_s.length
	if (length == 1) {
		rem_s = "00" + rem_s
	}
	else if (length == 2) {
		rem_s = "0" + rem_s	
	}
	document.getElementById('timer').innerHTML = sec + "." + rem_s
}

var key_array = []

function keypressed(event) {
	event = event || window.event
    var keycode = event.charCode || event.keyCode

	if(key_array.indexOf(keycode) != -1) {
		return
	}
	key_array.push(keycode)

    handle_keypressed(keycode)
}

function keyreleased(event) {
	key_array.pop(event)
	event = event || window.event
    var keycode = event.charCode || event.keyCode
	handle_keyreleased(keycode)
}

function startHold() {
	hold_timer.start(HOLD_TIME)
	$('#timer').animate({color: "#C83637" }, 200)
}

function cancelHold() {
	hold_timer.stop()
	hold_timer.reset()
	$('#timer').animate({color: "#B2E2E4" }, 200)
}

function endHold() {
	hold_timer.stop()
	hold_timer.reset()
	$('#timer').animate({color: "#FC946F" }, 200)
}

function handle_keypressed(key) {
	stopTimer()
	switch(key) {
		case 32: startHold()
	}
}

function handle_keyreleased(key) {
	switch(key) {
		case 32: 
			cancelHold()
			if(hold_timer.lap() < 0) {
				startTimer()
			}
	}
}

document.onkeydown 	= keypressed
document.onkeyup 	= keyreleased

/*
Mousetrap.bind('?', start)
Mousetrap.bind('p', swank)
*/