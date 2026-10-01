const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const BASE_URL = 'http://localhost:3000/api';

async function generateDummyImage(filename, content = 'fake image content') {
  const filePath = path.join(__dirname, filename);
  fs.writeFileSync(filePath, content);
  return filePath;
}

async function runTests() {
  console.log('--- STARTING B1 TESTS ---');
  
  // 1. Create two users
  const emailA = `testA_${Date.now()}@example.com`;
  const emailB = `testB_${Date.now()}@example.com`;
  const pass = 'password123';

  // We need real images for signup now since sharp validates magic bytes
  // I will just download a sample image or create a 1x1 pixel via a buffer for tests
  // Since we don't have one handy, I will construct a base64 tiny PNG
  const tinyPngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==";
  const realImagePath = path.join(__dirname, 'real.png');
  fs.writeFileSync(realImagePath, Buffer.from(tinyPngBase64, 'base64'));

  // Signup User A
  let formA = new FormData();
  formA.append('email', emailA);
  formA.append('password', pass);
  formA.append('pseudonym', 'UserA');
  formA.append('images', fs.createReadStream(realImagePath));
  formA.append('images', fs.createReadStream(realImagePath));

  let resA = await axios.post(`${BASE_URL}/auth/signup`, formA, {
    headers: formA.getHeaders(),
    validateStatus: () => true
  });
  const tokenA = resA.data.token;
  console.log('User A created, images:', resA.data.user.images.length);

  // Signup User B
  let formB = new FormData();
  formB.append('email', emailB);
  formB.append('password', pass);
  formB.append('pseudonym', 'UserB');
  formB.append('images', fs.createReadStream(realImagePath));
  formB.append('images', fs.createReadStream(realImagePath));

  let resB = await axios.post(`${BASE_URL}/auth/signup`, formB, {
    headers: formB.getHeaders(),
    validateStatus: () => true
  });
  const tokenB = resB.data.token;

  const authA = { headers: { Authorization: `Bearer ${tokenA}` } };
  const authB = { headers: { Authorization: `Bearer ${tokenB}` } };

  // Unauthenticated request
  const unauthRes = await axios.post(`${BASE_URL}/users/me/photos`, {}, { validateStatus: () => true });
  console.log('Unauthenticated request:', unauthRes.status === 401 ? 'PASS (401)' : 'FAIL');

  // SVG or renamed exe rejected
  const fakeImagePath = await generateDummyImage('fake.jpg', 'MZ\x90\x00\x03\x00\x00\x00'); // Fake exe header
  let formFake = new FormData();
  formFake.append('photo', fs.createReadStream(fakeImagePath));
  const badImageRes = await axios.post(`${BASE_URL}/users/me/photos`, formFake, {
    headers: { ...formFake.getHeaders(), Authorization: `Bearer ${tokenA}` },
    validateStatus: () => true
  });
  console.log('Fake/EXE image upload:', badImageRes.status === 500 || badImageRes.status === 400 ? 'PASS (Rejected)' : 'FAIL');

  // Upload up to 6 photos
  for (let i = 2; i < 6; i++) {
    let f = new FormData();
    f.append('photo', fs.createReadStream(realImagePath));
    await axios.post(`${BASE_URL}/users/me/photos`, f, {
      headers: { ...f.getHeaders(), Authorization: `Bearer ${tokenA}` }
    });
  }
  
  // Upload 7th photo (rejected)
  let form7 = new FormData();
  form7.append('photo', fs.createReadStream(realImagePath));
  const res7 = await axios.post(`${BASE_URL}/users/me/photos`, form7, {
    headers: { ...form7.getHeaders(), Authorization: `Bearer ${tokenA}` },
    validateStatus: () => true
  });
  console.log('7th photo upload:', res7.status === 400 ? 'PASS (Rejected)' : 'FAIL');

  // Fetch current photos for User A
  const meA = await axios.get(`${BASE_URL}/users/me`, authA);
  let imagesA = meA.data.images;

  // Reorder with foreign URL (rejected)
  const foreignReorder = [...imagesA];
  foreignReorder[0] = '/uploads/hacked-url.webp';
  const badReorder = await axios.put(`${BASE_URL}/users/me/photos/order`, { images: foreignReorder }, {
    ...authA, validateStatus: () => true
  });
  console.log('Reorder with foreign URL:', badReorder.status === 400 ? 'PASS (Rejected)' : 'FAIL');

  // Reorder valid permutation
  const validReorder = [...imagesA].reverse();
  const goodReorder = await axios.put(`${BASE_URL}/users/me/photos/order`, { images: validReorder }, authA);
  console.log('Reorder valid permutation:', goodReorder.status === 200 && goodReorder.data.images[0] === validReorder[0] ? 'PASS' : 'FAIL');
  imagesA = goodReorder.data.images;

  // Parallel reorders (concurrency check)
  const reorder1 = [...imagesA];
  const temp = reorder1[0]; reorder1[0] = reorder1[1]; reorder1[1] = temp;
  const reorder2 = [...imagesA].reverse();
  
  const p1 = axios.put(`${BASE_URL}/users/me/photos/order`, { images: reorder1 }, { ...authA, validateStatus: () => true });
  const p2 = axios.put(`${BASE_URL}/users/me/photos/order`, { images: reorder2 }, { ...authA, validateStatus: () => true });
  const [resP1, resP2] = await Promise.all([p1, p2]);
  
  const conflict = (resP1.status === 409 || resP2.status === 409);
  console.log('Parallel reorders conflict detection:', conflict ? 'PASS (409 returned)' : 'FAIL (No conflict)');

  // Refresh images after parallel
  const meAfterParallel = await axios.get(`${BASE_URL}/users/me`, authA);
  imagesA = meAfterParallel.data.images;

  // Delete down to 2
  while (imagesA.length > 2) {
    const urlToDelete = imagesA[imagesA.length - 1];
    const delRes = await axios.delete(`${BASE_URL}/users/me/photos`, { data: { url: urlToDelete }, ...authA });
    imagesA = delRes.data.images;
    
    // Check if file is removed from disk
    const filename = path.basename(urlToDelete);
    const diskPath = path.join(__dirname, '../../public/uploads', filename);
    const exists = fs.existsSync(diskPath);
    console.log(`File deleted from disk (${filename}):`, !exists ? 'PASS' : 'FAIL');
  }

  // Delete below 2 (rejected)
  const delBelow2 = await axios.delete(`${BASE_URL}/users/me/photos`, { 
    data: { url: imagesA[0] }, 
    ...authA, 
    validateStatus: () => true 
  });
  console.log('Delete below 2 photos:', delBelow2.status === 400 ? 'PASS (Rejected)' : 'FAIL');

  // Another user's data untouched
  const meB = await axios.get(`${BASE_URL}/users/me`, authB);
  console.log("User B's data untouched:", meB.data.images.length === 2 ? 'PASS' : 'FAIL');
}

runTests().catch(console.error);
