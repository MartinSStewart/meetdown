// port martinsstewart_crop_image_to_js : { requestId : Int, imageUrl : String, x : Int, y : Int, size : Int } -> Cmd msg
// port martinsstewart_crop_image_from_js : ({ requestId : Int, croppedImageUrl : String } -> msg) -> Sub msg

exports.init = async function(app) {
  app.ports.martinsstewart_crop_image_to_js.subscribe(function(data) {
    setImage(app, data);
  })
}

function setImage(app, data) {
    console.log(data);
    var canvas = document.createElement('canvas');
    canvas.width = 128;
    canvas.height = 128;
    canvas.style.display = "none";
    document.body.appendChild(canvas);
    var ctx = canvas.getContext('2d');

    var img = new Image();

    img.onload = function(){
      ctx.drawImage(img, -data.x, -data.y);
      var croppedImageUrl = canvas.toDataURL();
      document.body.removeChild(canvas);
      app.ports.martinsstewart_crop_image_from_js.send({ requestId: data.requestId, croppedImageUrl: croppedImageUrl });
    }

    img.src = data.imageUrl;
}