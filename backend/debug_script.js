require('dotenv').config();
const mongoose = require('mongoose');
const Order = require('./models/Order');
const BuyerProfile = require('./models/BuyerProfile');
const orderController = require('./controllers/orderController');

async function testImpact() {
    await mongoose.connect(process.env.MONGO_URI);

    const orders = await Order.find({ status: 'delivered' }).lean();
    if (orders.length === 0) return console.log('No delivered orders');

    // Find the exact user from the screenshot: 42 orders placed, 10 cancelled
    // Let's find all buyer profiles to see who has these stats
    const profiles = await BuyerProfile.find({});
    let targetUserId = null;
    for (const p of profiles) {
        const allOrders = await Order.find({ buyerId: p.userId }).lean();
        if (allOrders.length >= 40) { // e.g. 42
            console.log(`Found heavy buyer: ${p.userId} with ${allOrders.length} total orders.`);
            targetUserId = p.userId;
            break;
        }
    }

    if (!targetUserId) targetUserId = orders[0].buyerId;

    console.log('Testing for buyer ID:', targetUserId);

    const foundOrders = await Order.find({ buyerId: targetUserId, status: { $in: ['delivered', 'completed'] } });
    console.log('Found delivered/completed orders for query:', foundOrders.length);

    let totalQuantity = 0;
    for (const o of foundOrders) {
        totalQuantity += (o.quantityOrdered || 1);
    }
    console.log('Total quantity computed:', totalQuantity);

    // Run the actual function
    await orderController.recomputeBuyerImpact(targetUserId);
    const updatedProfile = await BuyerProfile.findOne({ userId: targetUserId });
    console.log('Profile impact after recompute:', updatedProfile.impact);

    process.exit(0);
}

testImpact().catch(console.error);
