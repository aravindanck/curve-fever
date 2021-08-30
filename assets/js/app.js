// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import topbar from "topbar"
import {LiveSocket} from "phoenix_live_view"

const colorCodes = new Map()
colorCodes["red"] = [255,0,0]
colorCodes["yellow"] = [255,255,0]
colorCodes["aqua"] = [0,255,255]
colorCodes["navy"] = [0,0,128]
colorCodes["blue"] = [0,0,255]
colorCodes["green"] = [0,128,0]
colorCodes["lime"] = [0,255,0]
colorCodes["olive"] = [128,128,0]
colorCodes["purple"] = [128,0,128]
colorCodes["teal"] = [0,128,128]

function setCanvas() {
  const c = document.getElementById("game-canvas");
  const ctx = c.getContext("2d");

  let data_arr = JSON.parse(c.getAttribute("data-value"));
  var canvasPixels = ctx.getImageData(0, 0, c.getAttribute("width"), c.getAttribute("height"));
  console.log("before", canvasPixels, canvasPixels.data);

  for (var i = 0; i < canvasPixels.data.length; i += 4) {
      
    let index = i/4;

    let data = data_arr[index]

    if (data != -1 && data != undefined) {
      // console.log("data", data);
      let color = data[0];
      console.log("Color ",  color);
      canvasPixels.data[i] = colorCodes[color][0];
      canvasPixels.data[i + 1] = colorCodes[color][1];     // green
      canvasPixels.data[i + 2] = colorCodes[color][2];     // blue
      canvasPixels.data[i + 3] = 255;

    } else {
      canvasPixels.data[i]     = 245;     // red
      canvasPixels.data[i + 1] = 245;     // green
      canvasPixels.data[i + 2] = 245;     // blue
      canvasPixels.data[i + 3] = 255;
    }
  }

  console.log("after", canvasPixels);
  ctx.putImageData(canvasPixels, 0, 0);
}

let Hooks = {}
Hooks.canvas = {
  mounted() {
    console.log("Canvas mounted");
    setCanvas();
    console.log("Set canvas called in mount")
  },
  updated() {
    console.log("Updated - 1");

    const c = document.getElementById("game-canvas");
    const ctx = c.getContext("2d");
    
    let diff_json = JSON.parse(document.getElementById("canvas-diff").getAttribute("data-value"));
    console.log(ctx, "Diff JSON : ", diff_json);
    console.log(diff_json['color'], diff_json['x1'], diff_json['y1'],diff_json['x2'], diff_json['y2'])

    ctx.strokeStyle = diff_json['color'];
    ctx.fillStyle = diff_json['color'];
    ctx.beginPath();
    ctx.lineWidth = 1;
    ctx.moveTo(diff_json['y1'], diff_json['x1']);
    ctx.lineTo(diff_json['y2'], diff_json['x2']);
    ctx.stroke();
    console.log("Drawn");
  }
}
// End of User defined JS

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket