const { ChartJSNodeCanvas } = require('chartjs-node-canvas');
const fs = require("fs");

const width = 400; //px
const height = 100; //px
const backgroundColour = 'transparent'; // Uses https://www.w3schools.com/tags/canvas_fillstyle.asp
const chartJSNodeCanvas = new ChartJSNodeCanvas({ width, height, backgroundColour });


(async () => {
    const github = process.argv[2]
    const category = process.argv[3]
    const completed = process.argv[4]
    const assigned = process.argv[5]
    const all = 11

    const configuration = {
        type: 'bar',
        data: {
            labels: [''],
            datasets: [{
                label: 'Completed',
                data: [completed],
                borderWidth: 1,
                backgroundColor: '#154c79',
                borderColor: '#063970'
            },
            {
                label: 'Assigned',
                data: [assigned],
                borderWidth: 1,
                backgroundColor: '#eab676',
                borderColor: '#e28743'
            }],
        },
        options: {
            indexAxis: 'y',
            scales: {
                x: {
                    ticks: {
                        stepSize: 1,
                        callback: function (value, index, ticks) {
                            if (value == 5)
                                return "C"
                            if (value == 8)
                                return "B"
                            if (value == all)
                                return "A"
                        }
                    },
                    max: all
                },
                y: {
                    stacked: true
                }
            }
        }
    };

    const image = await chartJSNodeCanvas.renderToBuffer(configuration);
    fs.writeFileSync(`test-data/progressReports/${github}/${category}.png`, image);
    console.log(github, category, completed, assigned)
})();
