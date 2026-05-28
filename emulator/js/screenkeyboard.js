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
    html += '<div style="left:700px;top:0px" id="KeyBackspace2">delete</div>';
    html += '<div style="left:0px;top:50px" id="KeyBackquote">`\t~</div>';
    html += '<div style="left:75px;top:50px" id="KeyQ">q</div>';
    html += '<div style="left:125px;top:50px" id="KeyW">w</div>';
    html += '<div style="left:175px;top:50px" id="key30">e</div>';
    html += '<div style="left:225px;top:50px" id="key24">r</div>';
    html += '<div style="left:275px;top:50px" id="key34">t</div>';
    html += '<div style="left:325px;top:50px" id="key26">y</div>';
    html += '<div style="left:375px;top:50px" id="key49">u</div>';
    html += '<div style="left:425px;top:50px" id="key51">i</div>';
    html += '<div style="left:475px;top:50px" id="key48">o</div>';
    html += '<div style="left:525px;top:50px" id="key27">p</div>';
    html += '<div style="left:575px;top:50px" id="key11">[\t{</div>';
    html += '<div style="left:625px;top:50px" id="key60">]\t}</div>';
    html += '<div style="left:675px;top:50px" id="key60">\\\t|</div>';
    html += '<div style="left:0px;top:100px" id="key65">tab</div>';
    html += '<div style="left:100px;top:100px" id="key46">a</div>';
    html += '<div style="left:150px;top:100px" id="key44">s</div>';
    html += '<div style="left:200px;top:100px" id="key19">d</div>';
    html += '<div style="left:250px;top:100px" id="key36">f</div>';
    html += '<div style="left:300px;top:100px" id="key38">g</div>';
    html += '<div style="left:350px;top:100px" id="key35">h</div>';
    html += '<div style="left:400px;top:100px" id="key32">j</div>';
    html += '<div style="left:450px;top:100px" id="key22">k</div>';
    html += '<div style="left:500px;top:100px" id="key43">l</div>';
    html += '<div style="left:550px;top:100px" id="key50">;\t:</div>';
    html += '<div style="left:600px;top:100px" id="key16">\'\t"</div>';
    html += '<div style="left:700px;top:100px" id="key16">return</div>';
    html += '<div style="left:0px;top:150px" id="key66">shift</div>';
    html += '<div style="left:125px;top:150px" id="key52">z</div>';
    html += '<div style="left:175px;top:150px" id="key21">x</div>';
    html += '<div style="left:225px;top:150px" id="key33">c</div>';
    html += '<div style="left:275px;top:150px" id="key28">v</div>';
    html += '<div style="left:325px;top:150px" id="key41">b</div>';
    html += '<div style="left:375px;top:150px" id="key45">n</div>';
    html += '<div style="left:425px;top:150px" id="key20">m</div>';
    html += '<div style="left:475px;top:150px" id="key18">,\t<</div>';
    html += '<div style="left:525px;top:150px" id="key13">.\t></div>';
    html += '<div style="left:575px;top:150px" id="key17">/\t?</div>';
    html += '<div style="left:650px;top:150px" id="key58">^</div>';
    html += '<div style="left:600px;top:200px" id="key57"><</div>';

    html += `
        <div
            id="key59"
            style="
                left:650px;
                top:200px;
                position:absolute;
                display:inline-block;
                transform:rotate(180deg);
            ">^
        </div>`;

    html += '<div style="left:700px;top:200px" id="key56">></div>';

    html += '<div style="left:0px;top:200px" id="key59">control</div>';
    html += '<div style="left:50px;top:200px" id="key56">option</div>';

    html += '<div style="left:300px;top:200px;width:125px" id="key54">space</div>';

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

    for (let i = 0; i < 59; i++) {
        let o = div.querySelector("#key" + i);
        if (o) {
            uiObjects[i] = o;
            let ii = i;
            o.addEventListener('touchstart', function(e) {
                touchmode = true;
                callKeyHandler(ii, true);
            });
            o.addEventListener('touchend', function(e) {
                callKeyHandler(ii, false);
            });
            o.addEventListener('pointerdown', function(e) {
                if (!touchmode) {
                    this.setPointerCapture(e.pointerId);
                    callKeyHandler(ii, true);
                }
            });
            o.addEventListener('pointerup', function(e) {
                if (!touchmode) {
                    this.releasePointerCapture(e.pointerId);
                    callKeyHandler(ii, false);
                }
            });
        }
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
