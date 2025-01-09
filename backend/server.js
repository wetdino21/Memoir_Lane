const express = require('express');
const faceapi = require('face-api.js');
const canvas = require('canvas');
const { Canvas, Image, ImageData } = canvas;
faceapi.env.monkeyPatch({ Canvas, Image, ImageData });
const app = express();
const port = 5000;

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

// Endpoint to compare two faces
app.post('/compare_faces', async (req, res) => {
  const { image1, image2 } = req.body; // Base64 encoded images

  const img1Buffer = Buffer.from(image1, 'base64');
  const img2Buffer = Buffer.from(image2, 'base64');
  
  const image1Canvas = await canvas.loadImage(img1Buffer);
  const image2Canvas = await canvas.loadImage(img2Buffer);

  const detections1 = await faceapi.detectSingleFace(image1Canvas).withFaceLandmarks().withFaceDescriptor();
  const detections2 = await faceapi.detectSingleFace(image2Canvas).withFaceLandmarks().withFaceDescriptor();

  if (detections1 && detections2) {
    const distance = faceapi.euclideanDistance(detections1.descriptor, detections2.descriptor);
    const result = distance < 0.6;  // Distance threshold for a match
    return res.json({ match: result });
  }

  return res.status(400).json({ error: 'No faces detected' });
});

// Start the server and load models
loadModels().then(() => {
  app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
  });
});
