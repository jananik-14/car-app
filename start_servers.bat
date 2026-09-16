@echo off
echo Starting OTP Verification Server (Port 5000)...
start "OTP Server (Port 5000)" cmd /k "cd 2._otp_verification\backend && node server.js"

echo Starting Vehicle Management Server (Port 5001)...
start "Vehicle Server (Port 5001)" cmd /k "cd 3._vehicle_management\backend && node server.js"

echo Starting Bidding Server (Port 5002)...
start "Bidding Server (Port 5002)" cmd /k "cd 5._bidding\backend && node server.js"

echo Starting Subscriptions Server (Port 5003)...
start "Subscriptions Server (Port 5003)" cmd /k "cd 4._subscriptions\backend && npm install && node server.js"

echo Starting Notifications Server (Port 5004)...
start "Notifications Server (Port 5004)" cmd /k "cd 6._notifications\backend && npm install && node server.js"

echo Starting Watchlist Server (Port 5005)...
start "Watchlist Server (Port 5005)" cmd /k "cd 7._watchlist\backend && npm install && node server.js"

echo All backend servers are starting in new windows!
pause
