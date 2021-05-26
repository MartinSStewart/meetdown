// port martinsstewart_crop_image_to_js : () -> Sub msg
// port martinsstewart_crop_image_from_js : ({ requestId : Int, croppedImageUrl : String } -> msg) -> Sub msg

exports.init = async function(app) {
  app.ports.martinsstewart_get_time_zone_to_js.subscribe(function() {
        var offset = new Date().getTimezoneOffset();
        app.ports.martinsstewart_get_time_zone_from_js.send(offset);
  })
}
