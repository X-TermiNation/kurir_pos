const express = require("express");
const app = express();
const cors = require("cors");
const bodyParser = require("body-parser");
const logger = require("morgan");
// const mongoose = require('mongoose')
const jwt = require("jsonwebtoken");
const Realm = require("realm");
const path = require("path");
const expressLayouts = require("express-ejs-layouts");
const WebSocket = require("ws");
const http = require("http");
const port = 3002;
const wsPort = 8080;
//http://192.168.1.197:3002
const UserRouter = require("./view-model-js/view-model-route/user");
const BarangRouter = require("./view-model-js/view-model-route/barang");
const CabangRouter = require("./view-model-js/view-model-route/cabang");
const GudangRouter = require("./view-model-js/view-model-route/gudang");
const TransaksiRouter = require("./view-model-js/view-model-route/transaksi");
const XenditRouter = require("./view-model-js/view-model-route/xendit/xendit");
const InvoiceRouter = require("./view-model-js/view-model-route/invoice");
app.use(logger("dev"));
app.use(expressLayouts);
app.set("view engine", "ejs");
app.use(express.static(path.join(__dirname, "public")));
var options = {
  keepAlive: 1,
  connectTimeoutMS: 30000,
  useNewUrlParser: true,
  useUnifiedTopology: true,
};

app.use(cors());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

const authRouter = require("./user_auth");
app.use("/auth", authRouter);
app.use("/user", UserRouter);
app.use("/barang", BarangRouter);
app.use("/cabang", CabangRouter);
app.use("/gudang", GudangRouter);
app.use("/transaksi", TransaksiRouter);
app.use("/auth", authRouter);
app.use("/xendit", XenditRouter);
app.use("/Invoice", InvoiceRouter);

app.use((req, res, next) => {
  console.log(`Received request: ${req.method} ${req.url}`);
  next();
});

app.use((err, req, res, next) => {
  console.error("Error handling request:", err);
  res.status(500).send("Internal Server Error");
});

const {
  initializeRealm,
} = require("./view-model-js/view-model-realm/realm_database");
const { default: Xendit } = require("xendit-node");
initializeRealm()
  .then(() => {
    const server = http.createServer(app);

    // Initialize the WebSocket server on a different port
    const wss = new WebSocket.Server({ noServer: true });

    // Handle HTTP upgrades to WebSocket
    server.on("upgrade", (request, socket, head) => {
      // Only allow WebSocket upgrades to the /ws path
      if (request.url === "/ws") {
        wss.handleUpgrade(request, socket, head, (ws) => {
          wss.emit("connection", ws, request);
        });
      } else {
        // Reject any other upgrades
        socket.destroy();
      }
    });

    // WebSocket server to handle incoming connections
    wss.on("connection", (ws) => {
      console.log("Client connected");

      // Listen for messages (live location updates)
      ws.on("message", (message) => {
        try {
          const data = JSON.parse(message);

          if (data.latitude && data.longitude) {
            console.log(
              `Received live position: Latitude: ${data.latitude}, Longitude: ${data.longitude}`
            );

            // Broadcast this location to all connected clients, if needed
            wss.clients.forEach((client) => {
              if (client.readyState === WebSocket.OPEN) {
                client.send(
                  JSON.stringify({
                    type: "live_location_update",
                    latitude: data.latitude,
                    longitude: data.longitude,
                  })
                );
              }
            });
          } else {
            console.log(`Received message: ${message}`);
          }
        } catch (err) {
          console.error("Error parsing message:", err);
        }
      });

      ws.on("close", () => {
        console.log("Client disconnected");
      });
    });

    app.listen(port, function () {
      console.log("Runnning on " + port);
    });
    server.listen(wsPort, () => {
      console.log(`WebSocket server running on ${wsPort}`);
    });
  })
  .catch((err) => {
    console.error("Failed to connect to Realm MongoDB:", err);
  });

module.exports = app;
