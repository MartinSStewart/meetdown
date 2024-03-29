/* port martinsstewart_crop_image_to_js :
    { requestId : Int
    , imageUrl : String
    , cropX : Int
    , cropY : Int
    , cropWidth : Int
    , cropHeight : Int
    , width : Int
    , height : Int
    }
    -> Cmd msg
*/
// port martinsstewart_crop_image_from_js : ({ requestId : Int, croppedImageUrl : String } -> msg) -> Sub msg

exports.init = async function (app) {
  app.ports.martinsstewart_crop_image_to_js.subscribe(function (data) {
    setImage(app, data);
  })

  app.ports.get_prefers_dark_theme_to_js.subscribe(function (data) {
    let localStorageValue = window.localStorage.getItem("prefersDarkTheme");
    if (localStorageValue !== null) {
      app.ports.got_prefers_dark_theme_from_js.send(JSON.parse(localStorageValue));
    }
    else if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      app.ports.got_prefers_dark_theme_from_js.send(true);
    }
    else {
      app.ports.got_prefers_dark_theme_from_js.send(false);
    }
  });

  app.ports.set_prefers_dark_theme_to_js.subscribe(function (data) {
    window.localStorage.setItem("prefersDarkTheme", JSON.stringify(data));
  });

  app.ports.set_language_to_js.subscribe(function (data) {
    window.localStorage.setItem("language", JSON.stringify(data));
  });

  app.ports.get_language_to_js.subscribe(function (data) {
    let localStorageValue = window.localStorage.getItem("language");
    if (localStorageValue !== null) {
      app.ports.got_language_from_js.send(JSON.parse(localStorageValue));
    }
    else {
      app.ports.got_language_from_js.send(navigator.language);
    }
  });
}

function setImage(app, data) {
  var canvas = document.createElement('canvas');
  canvas.width = data.cropWidth;
  canvas.height = data.cropHeight;
  canvas.style.display = "none";
  document.body.appendChild(canvas);
  var ctx = canvas.getContext('2d');


  var img = new Image();

  img.onload = function () {
    ctx.imageSmoothingEnabled = true;
    ctx.imageSmoothingQuality = "high";

    ctx.drawImage(img, data.cropX, data.cropY, data.width, data.height, 0, 0, data.cropWidth, data.cropHeight);
    var croppedImageUrl = canvas.toDataURL();
    document.body.removeChild(canvas);
    app.ports.martinsstewart_crop_image_from_js.send({ requestId: data.requestId, croppedImageUrl: croppedImageUrl });
  }

  img.src = data.imageUrl;
}