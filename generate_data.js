const fs = require('fs');

function generateSensorData() {
  const now = new Date();
  const startDate = new Date(2024, 2, 1); // January 1, 2024
  const endDate = now;

  const sensorTypes = ['temperature', 'humidity', 'pressure'];
  const sensorHistory = {};

  sensorTypes.forEach(type => {
    sensorHistory[type] = {};
  });

  let currentDate = startDate;
  while (currentDate <= endDate) {
    const timestamp = currentDate.getTime();

    sensorTypes.forEach(type => {
      let value;
      switch (type) {
        case 'temperature':
          value = 15 + Math.random() * 35; // 15-30
          break;
        case 'humidity':
          value = 40 + Math.random() * 60; // 40-70
          break;
        case 'pressure':
          value = 900 + Math.random() * 200; // 1000-1020
          break;
        default:
          value = 0;
      }

      sensorHistory[type][timestamp] = parseFloat(value.toFixed(1));
    });

    currentDate.setDate(currentDate.getDate() + 1); // Increment by one day
  }

  const sensorData = {
    sensor_history: sensorHistory,
    sensor_data: {
      temperature: 25.0,
      humidity: 62.0,
      pressure: 1013.0,
    },
  };

  return sensorData;
}

const data = generateSensorData();

fs.writeFileSync('data.json', JSON.stringify(data, null, 2));

console.log('Data generated and saved to data.json');