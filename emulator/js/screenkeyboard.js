function ScreenKeyboard(parentDocumentElement) {
    let html = '<link href="css/screenkeyboard.css" rel="stylesheet" type="text/css">';
    html += '<div>Real keyboard is also works</div>';

    html += '<div style="left:0px;top:0px" id="KeyEscape">esc</div>';
    html += '<div style="left:50px;top:0px" id="KeyDigit1">1\t!</div>';
    html += '<div style="left:100px;top:0px" id="KeyDigit2">2\t@</div>';
    html += '<div style="left:150px;top:0px" id="KeyDigit3">3\t#</div>';
    html += '<div style="left:200px;top:0px" id="KeyDigit4">4\t$</div>';
    html += '<div style="left:250px;top:0px" id="KeyDigit5">5\t%</div>';
    html += '<div style="left:300px;top:0px" id="KeyDigit6">6\t^</div>';
    html += '<div style="left:350px;top:0px" id="KeyDigit7">7\t&</div>';
    html += '<div style="left:400px;top:0px" id="KeyDigit8">8\t*</div>';
    html += '<div style="left:450px;top:0px" id="KeyDigit9">9\t(</div>';
    html += '<div style="left:500px;top:0px" id="KeyDigit0">0\t)</div>';
    html += '<div style="left:550px;top:0px" id="KeyMinus">-\t_</div>';
    html += '<div style="left:600px;top:0px" id="KeyEqual">=\t+</div>';
    html += '<div style="left:700px;top:0px" id="KeyBackspace">delete</div>';

    html += '<div style="left:0px;top:50px" id="KeyBackquote">`\t~</div>';
    html += '<div style="left:75px;top:50px" id="KeyKeyQ">q</div>';
    html += '<div style="left:125px;top:50px" id="KeyKeyW">w</div>';
    html += '<div style="left:175px;top:50px" id="KeyKeyE">e</div>';
    html += '<div style="left:225px;top:50px" id="KeyKeyR">r</div>';
    html += '<div style="left:275px;top:50px" id="KeyKeyT">t</div>';
    html += '<div style="left:325px;top:50px" id="KeyKeyY">y</div>';
    html += '<div style="left:375px;top:50px" id="KeyKeyU">u</div>';
    html += '<div style="left:425px;top:50px" id="KeyKeyI">i</div>';
    html += '<div style="left:475px;top:50px" id="KeyKeyO">o</div>';
    html += '<div style="left:525px;top:50px" id="KeyKeyP">p</div>';
    html += '<div style="left:575px;top:50px" id="KeyBracketLeft">[\t{</div>';
    html += '<div style="left:625px;top:50px" id="KeyBracketRight">]\t}</div>';
    html += '<div style="left:675px;top:50px" id="KeyBackslash">\\\t|</div>';

    html += '<div style="left:0px;top:100px" id="KeyTab">tab</div>';
    html += '<div style="left:100px;top:100px" id="KeyKeyA">a</div>';
    html += '<div style="left:150px;top:100px" id="KeyKeyS">s</div>';
    html += '<div style="left:200px;top:100px" id="KeyKeyD">d</div>';
    html += '<div style="left:250px;top:100px" id="KeyKeyF">f</div>';
    html += '<div style="left:300px;top:100px" id="KeyKeyG">g</div>';
    html += '<div style="left:350px;top:100px" id="KeyKeyH">h</div>';
    html += '<div style="left:400px;top:100px" id="KeyKeyJ">j</div>';
    html += '<div style="left:450px;top:100px" id="KeyKeyK">k</div>';
    html += '<div style="left:500px;top:100px" id="KeyKeyL">l</div>';
    html += '<div style="left:550px;top:100px" id="KeySemicolon">;\t:</div>';
    html += '<div style="left:600px;top:100px" id="KeyQuote">\'\t"</div>';
    html += '<div style="left:700px;top:100px" id="KeyEnter">return</div>';

    html += '<div style="left:0px;top:150px" id="KeyShiftLeft">shift</div>';
    html += '<div style="left:125px;top:150px" id="KeyKeyZ">z</div>';
    html += '<div style="left:175px;top:150px" id="KeyKeyX">x</div>';
    html += '<div style="left:225px;top:150px" id="KeyKeyC">c</div>';
    html += '<div style="left:275px;top:150px" id="KeyKeyV">v</div>';
    html += '<div style="left:325px;top:150px" id="KeyKeyB">b</div>';
    html += '<div style="left:375px;top:150px" id="KeyKeyN">n</div>';
    html += '<div style="left:425px;top:150px" id="KeyKeyM">m</div>';
    html += '<div style="left:475px;top:150px" id="KeyComma">,\t<</div>';
    html += '<div style="left:525px;top:150px" id="KeyPeriod">.\t></div>';
    html += '<div style="left:575px;top:150px" id="KeySlash">/\t?</div>';
    html += '<div style="left:650px;top:150px" id="KeyArrowUp">^</div>';
    html += '<div style="left:600px;top:200px" id="KeyArrowLeft"><</div>';

    html += `
        <div
            id="KeyArrowDown"
            style="
                left:650px;
                top:200px;
                position:absolute;
                display:inline-block;
                transform:rotate(180deg);
            ">^
        </div>`;

    html += '<div style="left:700px;top:200px" id="KeyArrowRight">></div>';

    html += '<div style="left:0px;top:200px" id="KeyControlLeft">control</div>';
    html += '<div style="left:50px;top:200px" id="KeyAltLeft">option</div>';
    html += '<div style="left:300px;top:200px;width:125px" id="KeySpace">space</div>';

    let div = document.createElement('div');
    div.className = "keyboard";
    div.innerHTML = html;
    (parentDocumentElement ? parentDocumentElement : document.body).appendChild(div);

    let uiObjects = [];
    let keyHandler = null;
    let touchmode = false;

    function callKeyHandler(keyCode, press) {
        if (keyHandler)
            keyHandler(keyCode, press);
    }

    const keys = div.querySelectorAll('[id^="Key"]');

    for (const o of keys) {
        const keyCode = o.id.slice(3);
        uiObjects[keyCode] = o;
        o.addEventListener('touchstart', function(e) {
            touchmode = true;
            callKeyHandler(keyCode, true);
        });
        o.addEventListener('touchend', function(e) {
            callKeyHandler(keyCode, false);
        });
        o.addEventListener('pointerdown', function(e) {
            if (!touchmode) {
                this.setPointerCapture(e.pointerId);
                callKeyHandler(keyCode, true);
            }
        });
        o.addEventListener('pointerup', function(e) {
            if (!touchmode) {
                this.releasePointerCapture(e.pointerId);
                callKeyHandler(keyCode, false);
            }
        });
    }

    this.setKeyHandler = function(handler) {
        keyHandler = handler;
    };

    this.keyPressed = function(index, pressed) {
        let key = uiObjects[index];
        if (key) {
            if (pressed)
                key.classList.add("p");
            else
                key.classList.remove("p");
        }
    };
}
