const socketIo = require("socket.io");
const Message = require("../models/Message");

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

        // Volunteer/Buyer/Seller joins their order room
        socket.on("join_order", (orderId) => {
            socket.join(orderId);
            console.log(`Socket ${socket.id} joined room: ${orderId}`);
        });

        // Chat message handler
        socket.on("send_message", async (data) => {
            console.log(`[Socket] received send_message from ${socket.id}:`, data);
            try {
                const { orderId, senderId, senderRole, text } = data;

                // Save to database
                const newMessage = new Message({
                    orderId,
                    senderId,
                    senderRole,
                    text
                });
                await newMessage.save();

                // Broadcast to everyone in the room (including sender if they listen, or sender can just add it locally)
                // We'll broadcast to the room. The sender will receive it too, or we can use socket.to(orderId).emit
                console.log(`[Socket] Broadcasting receive_message to room ${orderId}:`, newMessage.toObject());
                io.to(orderId).emit("receive_message", newMessage.toObject());
            } catch (error) {
                console.error("Socket send_message error:", error);
            }
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
