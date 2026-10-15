const bool kDevMode = bool.fromEnvironment('DEV_MODE', defaultValue: true);
const String kDevTestOtp = '1234';
const String kDevAdminPhone = '9999999999';
const int kTokenAmount = 25000;
const bool kTokenRefundable = false;

// Bank details for NEFT/RTGS wire transfers
// TODO: Set real bank details (kBankName, kAccountName, kAccountNumber, kIfsc) before production deployment.
const String kBankName = 'HDFC Bank';
const String kAccountName = 'Wheels2Drive Pvt Ltd';
const String kAccountNumber = '50200012345678';
const String kIfsc = 'HDFC0001234';
