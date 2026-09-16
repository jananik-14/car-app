const Subscription = require('../models/Subscription');

exports.getSubscriptionStatus = async (req, res) => {
    try {
        const { phoneNumber } = req.params;
        const subscription = await Subscription.findOne({ phoneNumber, status: 'active' });
        
        if (!subscription) {
            return res.status(200).json({ success: true, data: null, message: "No active subscription" });
        }
        
        res.status(200).json({ success: true, data: subscription });
    } catch (error) {
        console.error('Error fetching subscription:', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

exports.subscribe = async (req, res) => {
    try {
        const { phoneNumber, planId, durationInDays } = req.body;
        
        if (!phoneNumber || !planId || !durationInDays) {
            return res.status(400).json({ success: false, message: 'Missing required fields' });
        }

        const startDate = new Date();
        const endDate = new Date();
        endDate.setDate(startDate.getDate() + durationInDays);

        // Cancel existing active subscriptions
        await Subscription.updateMany({ phoneNumber, status: 'active' }, { status: 'cancelled' });

        const newSubscription = new Subscription({
            phoneNumber,
            planId,
            startDate,
            endDate,
            status: 'active'
        });

        await newSubscription.save();

        res.status(201).json({ success: true, message: 'Subscribed successfully', data: newSubscription });
    } catch (error) {
        console.error('Error creating subscription:', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};
