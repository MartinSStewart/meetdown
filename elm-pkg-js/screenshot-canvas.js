// port martinsstewart_screenshot_canvas_to_js : String -> Cmd msg

exports.init = async function(app) {
  app.ports.martinsstewart_screenshot_canvas_to_js.subscribe(function(data) {
    setImage(data);
  })
}

function setImage(data) {
    console.log(data);
    var canvas = document.getElementById(data.canvasId);
    var ctx = canvas.getContext('2d');
    
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    var img = new Image();

    img.onload = function(){
      ctx.drawImage(img, 0, 0);
    }
    //img.setAttribute("src", data.image);
    var blob = new Blob([data.image.buffer]);
    img.src = window.URL.createObjectURL(blob);
}