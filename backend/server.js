const express = require('express');
const faceapi = require('face-api.js');
const canvas = require('canvas');
const { Pool } = require('pg'); //for postgres
const crypto = require('crypto');  // encryption SHA256
const { Canvas, Image, ImageData } = canvas;
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });
const app = express();
const port = 5000;

// PostgreSQL connection
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'memoir_lane',
  password: '123456',
  port: 5432,
});

// Load models for face-api.js (ensure you have the models folder)
async function loadModels() {
  await faceapi.nets.ssdMobilenetv1.loadFromDisk('./models');
  await faceapi.nets.faceRecognitionNet.loadFromDisk('./models');
  await faceapi.nets.faceLandmark68Net.loadFromDisk('./models');
}

// Setup Express to handle incoming POST requests with image data
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use(express.static('public'));

// // Endpoint to compare two faces
// app.post('/compare_faces', async (req, res) => {
//   const { image1, image2 } = req.body; // Base64 encoded images

//   const img1Buffer = Buffer.from(image1, 'base64');
//   const img2Buffer = Buffer.from(image2, 'base64');

//   const image1Canvas = await canvas.loadImage(img1Buffer);
//   const image2Canvas = await canvas.loadImage(img2Buffer);

//   const detections1 = await faceapi.detectSingleFace(image1Canvas).withFaceLandmarks().withFaceDescriptor();
//   const detections2 = await faceapi.detectSingleFace(image2Canvas).withFaceLandmarks().withFaceDescriptor();

//   if (detections1 && detections2) {
//     const distance = faceapi.euclideanDistance(detections1.descriptor, detections2.descriptor);
//     const result = distance < 0.6;  // Distance threshold for a match
//     return res.json({ match: result });
//   }

//   return res.status(400).json({ error: 'No faces detected' });
// });

app.post('/compare_faces', async (req, res) => {
  const { image1 } = req.body; // Base64 encoded image uploaded during login

  const img1Buffer = Buffer.from(image1, 'base64');
  const image1Canvas = await canvas.loadImage(img1Buffer);
  const detections1 = await faceapi.detectSingleFace(image1Canvas).withFaceLandmarks().withFaceDescriptor();

  if (!detections1) {
    return res.status(400).json({ error: 'No face detected in the uploaded image' });
  }

  try {
    // Query the database for all users' face images
    const users = await pool.query('SELECT id, picture FROM USERS');
    for (let user of users.rows) {
      const img2Buffer = Buffer.from(user.picture, 'base64');
      const image2Canvas = await canvas.loadImage(img2Buffer);

      const detections2 = await faceapi.detectSingleFace(image2Canvas).withFaceLandmarks().withFaceDescriptor();

      if (detections2) {
        const distance = faceapi.euclideanDistance(detections1.descriptor, detections2.descriptor);
        if (distance < 0.6) {  // Match found
          return res.json({ match: true, user_id: user.id });
        }
      }
    }

    return res.json({ match: false });

  } catch (err) {
    console.error('Error comparing faces:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});


// CREATE ACCOUNT
app.post('/create_acc', async (req, res) => {
  const { email, password, phone_number, picture } = req.body;

  // Hash the password using SHA-256
  const hashedPassword = crypto.createHash('sha256').update(password).digest('hex');
  const face = picture ? Buffer.from(picture, 'base64') : null;
  const insert = await pool.query(`INSERT INTO USERS (email, password, phone_number, picture) VALUES($1, $2, $3, $4)`, [email, hashedPassword, phone_number, face]);
  if (insert.rowCount > 0) {
    console.log('Inserted succ');
    res.status(200).json();
  } else {
    console.log('Failed to insert');
    res.status(400).json();
  }
});

// CHECK EXISTING EMAIL
app.post('/check_existing_email', async (req, res) => {
  const { email } = req.body;

  try {
    const result = await pool.query('SELECT * FROM USERS WHERE email = $1', [email]);
    if (result.rows.length > 0) {
      return res.status(400).json({ error: 'Email already exists' });
    }
    return res.status(200).json({ message: 'Email is available' });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Server error' });
  }
});

// CHECK EXISTING PHONE NUMBER
app.post('/check_existing_phone', async (req, res) => {
  const { phone_number } = req.body;

  try {
    const result = await pool.query('SELECT * FROM USERS WHERE phone_number = $1', [phone_number]);
    if (result.rows.length > 0) {
      return res.status(400).json({ error: 'Phone number already exists' });
    }
    return res.status(200).json({ message: 'Phone number is available' });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Server error' });
  }
});

// LOGIN ACC
app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    // Hash the provided password
    const hashedPassword = crypto.createHash('sha256').update(password).digest('hex');

    const result = await pool.query(
      `SELECT id FROM users WHERE email = $1 AND password = $2`,
      [email, hashedPassword]
    );

    if (result.rowCount > 0) {
      console.log('Login successful');
      res.status(200).json(result.rows[0].id);
    } else {
      console.log('Invalid email or password');
      res.status(400).json();
    }
  } catch (err) {
    console.error('Error during login:', err);
    res.status(500).json({
      message: 'Internal server error',
    });
  }
});


// Fetch User Details
app.post('/fetch_user', async (req, res) => {
  try {
    const { userId } = req.body;
    const result = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);

    if (result.rows.length === 0) {
      console.error('User not found');
      return res.status(404).json({ message: 'User not found' });
    }

    console.error('Fetch user success');
    result.rows[0].picture = result.rows[0].picture.toString('base64');
    res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching user details:', error);
    res.status(500).json({ message: 'Failed to fetch user details' });
  }
});

// Fetch Diaries
app.post('/fetch_diary', async (req, res) => {
  const { user_id } = req.body;
  console.log(user_id);
  try {
    const result = await pool.query('SELECT * FROM diary where user_id = $1', [user_id]);

    if (result.rows.length) {
      console.log('Fetched diaries');
      res.status(200).json(result.rows);
    } else {
      console.log('No Fetched diaries');
      res.status(400).json(result.rows);
    }

  } catch (error) {
    console.error('Error fetching diaries:', error);
    res.status(500).json({ message: 'Failed to fetch diaries' });
  }
});

// Delete Diary
app.delete('/delete_diary/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query('DELETE FROM diary WHERE id = $1', [id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Diary not found' });
    }

    res.status(200).json({ message: 'Diary deleted successfully' });
  } catch (error) {
    console.error('Error deleting diary:', error);
    res.status(500).json({ message: 'Failed to delete diary' });
  }
});

// Create Diary
app.post('/create_diary', async (req, res) => {
  const { title, description, user_id } = req.body;

  try {
    const result = await pool.query(
      'INSERT INTO diary (title, description, user_id) VALUES ($1, $2, $3) RETURNING *',
      [title, description, user_id]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error saving diary:', error);
    res.status(500).json({ message: 'Error saving diary' });
  }
});

// Update Diary
app.put('/update_diary/:id', async (req, res) => {
  const { id } = req.params;
  const { title, description } = req.body;

  try {
    const result = await pool.query(
      'UPDATE diary SET title = $1, description = $2 WHERE id = $3 RETURNING *',
      [title, description, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Diary not found' });
    }

    res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error('Error updating diary:', error);
    res.status(500).json({ message: 'Error updating diary' });
  }
});






// Start the server and load models
loadModels().then(() => {
  app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
  });
});
