const mongoose = require('mongoose');

const subscriptionUri = "mongodb+srv://indhumathi03122006_db_user:aNNCliFBINnJzH1A@cluster0.o2pe1yl.mongodb.net/wheels24drive_subscriptions_db?appName=Cluster0";
const notificationUri = "mongodb+srv://indhumathi03122006_db_user:aNNCliFBINnJzH1A@cluster0.o2pe1yl.mongodb.net/wheels24drive_notifications_db?appName=Cluster0";

const SubscriptionSchema = new mongoose.Schema({
    phoneNumber: String,
    planId: String,
    status: String,
    startDate: Date,
    endDate: Date
});

const NotificationSchema = new mongoose.Schema({
    phoneNumber: String,
    title: String,
    message: String,
    isRead: Boolean,
    createdAt: Date
});

async function seedData() {
    console.log("Connecting to Subscriptions DB...");
    const subConn = await mongoose.createConnection(subscriptionUri).asPromise();
    const Subscription = subConn.model('Subscription', SubscriptionSchema);
    
    // Insert a dummy subscription to force database creation
    await Subscription.create({
        phoneNumber: "dummy_init",
        planId: "basic",
        status: "active",
        startDate: new Date(),
        endDate: new Date()
    });
    console.log("Subscriptions DB created and seeded.");
    await subConn.close();

    console.log("Connecting to Notifications DB...");
    const notifConn = await mongoose.createConnection(notificationUri).asPromise();
    const Notification = notifConn.model('Notification', NotificationSchema);

    // Insert a dummy notification to force database creation
    await Notification.create({
        phoneNumber: "dummy_init",
        title: "Welcome!",
        message: "Your notifications database is ready.",
        isRead: false,
        createdAt: new Date()
    });
    console.log("Notifications DB created and seeded.");
    await notifConn.close();
    
    console.log("All missing databases successfully created!");
}

seedData().catch(console.error);
