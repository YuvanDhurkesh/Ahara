const socketIo = require("socket.io");

let io;

exports.init = (server) => {
    io = socketIo(server, {
        cors: {
            origin: "*",
            methods: ["GET", "POST"]
        }
    });

    console.log("Socket.io initialized ⚡");

    io.on("connection", (socket) => {
        console.log(`New client connected: ${socket.id}`);

        // Volunteer joins their order room
        socket.on("join_order", (orderId) => {
            socket.join(orderId);
            console.log(`Socket ${socket.id} joined room: ${orderId}`);
        });

        // Volunteer sends location update
        socket.on("update_location", ({ orderId, lat, lng }) => {
            console.log(`Location update for ${orderId}: ${lat}, ${lng}`);
            // Broadcast to everyone in the room (buyer/seller)
            io.to(orderId).emit("location_updated", { lat, lng });
        });

        socket.on("disconnect", () => {
            console.log(`Client disconnected: ${socket.id}`);
        });
    });

    return io;
};

exports.getIo = () => {
    if (!io) {
        throw new Error("Socket.io not initialized!");
    }
    return io;
};
