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
colorCodes["deeppink"] = [255,20,147]
colorCodes["orangered"] = [255,69,0]
colorCodes["navy"] = [0,0,128]
colorCodes["blue"] = [0,0,255]
colorCodes["green"] = [0,128,0]
colorCodes["lime"] = [0,255,0]
colorCodes["black"] = [0,0,0]
colorCodes["purple"] = [128,0,128]
colorCodes["saddlebrown"] = [139,69,19]

function setCanvas() {
  const c = document.getElementById("game-canvas");
  const ctx = c.getContext("2d");

  let data_arr = JSON.parse(c.getAttribute("data-value"));
  var canvasPixels = ctx.getImageData(0, 0, c.getAttribute("width"), c.getAttribute("height"));

  for (var i = 0; i < canvasPixels.data.length; i += 4) {
      
    let index = i/4;

    let data = data_arr[index]

    if (data != -1 && data != undefined) {
      let color = data[0];
      canvasPixels.data[i] = colorCodes[color][0];
      canvasPixels.data[i + 1] = colorCodes[color][1];     // green
      canvasPixels.data[i + 2] = colorCodes[color][2];     // blue
      canvasPixels.data[i + 3] = 255;

    } else {
      canvasPixels.data[i]     = 255;     // red
      canvasPixels.data[i + 1] = 255;     // green
      canvasPixels.data[i + 2] = 255;     // blue
      canvasPixels.data[i + 3] = 255;
    }
  }

  ctx.putImageData(canvasPixels, 0, 0);
}

let Hooks = {}
Hooks.canvas = {
  mounted() {
    console.log("Canvas mounted");
    setCanvas();
  },
  updated() {
    console.log("Updated");

    const c = document.getElementById("game-canvas");
    const ctx = c.getContext("2d");
    
    let diff_json_arr = JSON.parse(document.getElementById("canvas-diff")
                            .getAttribute("data-value"));

    diff_json_arr.forEach(diff_json => { 
      ctx.strokeStyle = diff_json['color'];
      ctx.fillStyle = diff_json['color'];
      ctx.beginPath();
      ctx.lineWidth = 1;
      ctx.moveTo(diff_json['y1'], diff_json['x1']);
      ctx.lineTo(diff_json['y2'], diff_json['x2']);
      ctx.stroke();
    });
  }
}

Hooks.gamestate ={
  mounted(){
    console.log("Game state mounted")
  },
  updated() {
    console.log("Game State Changed")
    window.location.reload()
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