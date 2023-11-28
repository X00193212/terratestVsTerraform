document.getElementById('calculate').addEventListener('click', () => {
    const systolic = document.getElementById('systolic').value;
    const diastolic = document.getElementById('diastolic').value;

    // Send an HTTP request to the server to calculate the blood pressure
    fetch('/calculate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ systolic, diastolic }),
        })
        .then((response) => response.json())
        .then((data) => {
            const result = document.getElementById('result');
            result.innerHTML = `Systolic: ${data.systolic} mm Hg<br>Diastolic: ${data.diastolic} mm Hg`;
        });
});