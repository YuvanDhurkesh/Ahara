const http = require('http');

const PORT = 5000;
const TEST_USER = {
    firebaseUID: {
        firebaseUid: "test_volunteer_123",
        name: "Manual Tester",
        email: "manual@test.com",
        role: "Volunteer"
    }
};

const makeRequest = (path, method, body) => {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: PORT,
            path: path,
            method: method,
            headers: { 'Content-Type': 'application/json' }
        };

        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    resolve({ status: res.statusCode, body: JSON.parse(data) });
                } catch (e) {
                    resolve({ status: res.statusCode, body: data });
                }
            });
        });

        req.on('error', (e) => reject(e));
        if (body) req.write(JSON.stringify(body));
        req.end();
    });
};

async function runVerification() {
    console.log("🚀 Starting Manual Verification...");

    try {
        // 1. Create User
        console.log("\n1️⃣  Creating Test User...");
        const createRes = await makeRequest('/api/users/create', 'POST', TEST_USER);
        if (createRes.status !== 201 && createRes.status !== 200) {
            throw new Error(`Failed to create user: ${createRes.status}`);
        }
        console.log("✅ User Created:", TEST_USER.firebaseUID.firebaseUid);

        // 2. Check Initial Profile
        console.log("\n2️⃣  Checking Initial Profile...");
        const initProfile = await makeRequest(`/api/users/profile/${TEST_USER.firebaseUID.firebaseUid}`, 'GET');
        console.log("   Points:", initProfile.body.points);
        console.log("   Level:", initProfile.body.level);

        // 3. Add Points (Simulate Delivery)
        console.log("\n3️⃣  Simulating 'COMPLETE_DELIVERY' (+200 pts)...");
        const pointsRes = await makeRequest('/api/users/points/add', 'POST', {
            userId: TEST_USER.firebaseUID.firebaseUid,
            actionType: 'COMPLETE_DELIVERY'
        });
        console.log("✅ API Response:", pointsRes.body.message);
        console.log("   Added:", pointsRes.body.added);

        // 4. Verify Update
        console.log("\n4️⃣  Verifying Updated Profile...");
        const finalProfile = await makeRequest(`/api/users/profile/${TEST_USER.firebaseUID.firebaseUid}`, 'GET');
        console.log("   Points:", finalProfile.body.points);
        console.log("   Level:", finalProfile.body.level);
        console.log("   Badges:", finalProfile.body.badges);

        if (finalProfile.body.points === (initProfile.body.points + 200)) {
            console.log("\n🎉 SUCCESS! Points were added correctly.");
        } else {
            console.log("\n❌ FAILURE! Points mismatch.");
        }

    } catch (error) {
        console.error("\n❌ Error during verification:", error.message);
        console.log("⚠️  Make sure the backend server is running on port 5000!");
    }
}

runVerification();
