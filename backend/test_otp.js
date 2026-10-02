const axios = require('axios');

async function test() {
  try {
    console.log('--- TRIGGERING OTP REQUEST ---');
    const req = await axios.post('http://localhost:3000/api/auth/otp/request', { email: 'tester@wehere.com' });
    console.log('Response:', req.data);
    
    console.log('\n--- TRIGGERING OTP VERIFY ---');
    const ver = await axios.post('http://localhost:3000/api/auth/otp/verify', { email: 'tester@wehere.com', otp: '123456' });
    console.log('Response:', ver.data);
  } catch(e) {
    console.error(e.response ? e.response.data : e.message);
  }
}
test();
