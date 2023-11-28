const express = require('express');
const app = express();
const port = 3000;

app.use(express.static('public'));

app.get('/', (req, res) => {
    res.sendFile(__dirname + '/public/index.html');
});

app.post('/calculate', express.json(), (req, res) => {
    const systolic = req.body.systolic;
    const diastolic = req.body.diastolic;

    // Implement your blood pressure calculation logic here

    // For a simple example, we'll just return the values
    res.json({ systolic, diastolic });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`Server is running on http://localhost:${port}`);
});