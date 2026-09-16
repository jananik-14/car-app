const sendSMS = async (phoneNumber, message) => {
    try {
        // TODO: Replace with real SMS provider (e.g. Twilio, AWS SNS, Fast2SMS)
        console.log('----------------------------------------------------');
        console.log(`[SMS SERVICE STUB] Sending SMS to ${phoneNumber}`);
        console.log(`[MESSAGE] ${message}`);
        console.log('----------------------------------------------------');
        
        // Simulating network delay
        await new Promise(resolve => setTimeout(resolve, 500));
        
        return { success: true, message: 'SMS sent successfully' };
    } catch (error) {
        console.error('[SMS SERVICE ERROR]', error);
        return { success: false, message: 'Failed to send SMS' };
    }
};

module.exports = {
    sendSMS
};
