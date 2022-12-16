const { ChartJSNodeCanvas } = require('chartjs-node-canvas');
const fs = require("fs");

const width = 400; //px
const height = 100; //px
const backgroundColour = 'white'; // Uses https://www.w3schools.com/tags/canvas_fillstyle.asp
const chartJSNodeCanvas = new ChartJSNodeCanvas({ width, height, backgroundColour });


(async () => {
    const studentName = process.argv[2]
    const completed = process.argv[3]
    const assigned = process.argv[4]
    
    const configuration = {
        type: 'bar',
        data: {
            labels: [''],
            datasets: [{
                label: 'Completed',
                data: [completed],
                borderWidth: 1,
            },
            {
                label: 'Assigned',
                data: [assigned],
                borderWidth: 1
            },
            {
                label: 'all',
                data: [10],
                borderWidth: 1
            }],
        },
        options: {
            indexAxis: 'y',
            scales: {
                xAxes: {
                    ticks: {
                        stepSize: 1,
                        callback: function (value, index, ticks) {
                            if (value == 5)
                                return "C"
                            if (value == 8)
                                return "B"
                            if (value == 10)
                                return "A"
                        }
                    }
                },
                yAxes: {
                    barPercentage: 0.4,
                    beginAtZero: true,
                    stacked: true
                }
            }
        }
    };
    
    const image = await chartJSNodeCanvas.renderToBuffer(configuration);
    fs.writeFileSync('lib/mychart.png', image);
    console.log(studentName, completed, assigned)
})();
