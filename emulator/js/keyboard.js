function Keyboard(screenKeyboard) {
    const pressed = new Set();
    let row = 0x00;

    this.read = function() {
        let res = 0x00;
        switch (row) {
            case (0x01 << 0):
                res = (+pressed.has("Escape") << 0) |
                    (+pressed.has("Digit1") << 1) |
                    (+pressed.has("Digit2") << 2) |
                    (+pressed.has("Digit3") << 3) |
                    (+pressed.has("Digit4") << 4) |
                    (+pressed.has("Digit5") << 5) |
                    (+pressed.has("Digit6") << 6) |
                    (+pressed.has("Digit7") << 7);
                break;
            case (0x01 << 1):
                res = (+pressed.has("Digit8") << 0) |
                    (+pressed.has("Digit9") << 1) |
                    (+pressed.has("Digit0") << 2) |
                    (+pressed.has("Minus") << 3) |
                    (+pressed.has("Equal") << 4) |
                    (+pressed.has("Backspace") << 5) |
                    (+pressed.has("Backquote") << 6) |
                    (+pressed.has("KeyQ") << 7);
                break;
            case (0x01 << 2):
                res = (+pressed.has("KeyW") << 0) |
                    (+pressed.has("KeyE") << 1) |
                    (+pressed.has("KeyR") << 2) |
                    (+pressed.has("KeyT") << 3) |
                    (+pressed.has("KeyY") << 4) |
                    (+pressed.has("KeyU") << 5) |
                    (+pressed.has("KeyI") << 6) |
                    (+pressed.has("KeyO") << 7);
                break;
            case (0x01 << 3):
                res = (+pressed.has("KeyP") << 0) |
                    (+pressed.has("BracketLeft") << 1) |
                    (+pressed.has("BracketRight") << 2) |
                    (+pressed.has("Backslash") << 3) |
                    (+pressed.has("Tab") << 4) |
                    (+pressed.has("KeyA") << 5) |
                    (+pressed.has("KeyS") << 6) |
                    (+pressed.has("KeyD") << 7);
                break;
            case (0x01 << 4):
                res = (+pressed.has("KeyF") << 0) |
                    (+pressed.has("KeyG") << 1) |
                    (+pressed.has("KeyH") << 2) |
                    (+pressed.has("KeyJ") << 3) |
                    (+pressed.has("KeyK") << 4) |
                    (+pressed.has("KeyL") << 5) |
                    (+pressed.has("Semicolon") << 6) |
                    (+pressed.has("Quote") << 7);
                break;
            case (0x01 << 5):
                res = (+pressed.has("Enter") << 0) |
                    (+pressed.has("ShiftLeft") << 1) |
                    (+pressed.has("ShiftRight") << 1) |
                    (+pressed.has("KeyZ") << 2) |
                    (+pressed.has("KeyX") << 3) |
                    (+pressed.has("KeyC") << 4) |
                    (+pressed.has("KeyV") << 5) |
                    (+pressed.has("KeyB") << 6) |
                    (+pressed.has("KeyN") << 7);
                break;
            case (0x01 << 6):
                res = (+pressed.has("KeyM") << 0) |
                    (+pressed.has("Comma") << 1) |
                    (+pressed.has("Period") << 2) |
                    (+pressed.has("Slash") << 3) |
                    (+pressed.has("ArrowUp") << 4) |
                    (+pressed.has("ControlLeft") << 5) |
                    (+pressed.has("ControlRight") << 5) |
                    (+pressed.has("AltLeft") << 6) |
                    (+pressed.has("AltRight") << 6) |
                    (+pressed.has("Space") << 7);
                break;
            case (0x01 << 7):
                res = (+pressed.has("ArrowLeft") << 0) |
                    (+pressed.has("ArrowDown") << 1) |
                    (+pressed.has("ArrowRight") << 2);
                break;
            default:
                res = 0x00;
        }
        return res;
    }
    this.write = function(value) {
        row = value & 0xFF;
    }
    function onKeyUp(e) {
        pressed.delete(e.code);
    }
    function onKeyDown(e) {
        if (e.repeat) return;
        if (['ArrowUp','ArrowDown','ArrowLeft','ArrowRight','Space'].includes(e.code)) e.preventDefault();
        pressed.add(e.code);
        //console.log('DOWN', e.key, e.code);
    }
    function screenKeyboardKeyHandler(keyCode, isPressed) {
        if (isPressed) {
            pressed.add(keyCode);
        } else {
            pressed.delete(keyCode);
        }
    }
    window.addEventListener('keydown', onKeyDown);
    window.addEventListener('keyup', onKeyUp);
    if (screenKeyboard) {
        screenKeyboard.setKeyHandler(screenKeyboardKeyHandler)
    }
}
