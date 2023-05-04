const { ChartJSNodeCanvas } = require('chartjs-node-canvas');
const fs = require("fs");

const width = 400;
const height = 100;
const backgroundColour = 'transparent';
const chartJSNodeCanvas = new ChartJSNodeCanvas({ width, height, backgroundColour });

(async () => {
    const input_file = process.argv[2];
    const data = JSON.parse(fs.readFileSync(input_file, 'utf-8'));

    const thresholds = data.thresholds;
    const categories = data.categories;
    const font_color = data.colors.font_color;
    const grid_color = data.colors.grid_color;
    const tick_color = data.colors.tick_color;
    const output_file = data.output_file;

    const categoryTitles = Object.keys(categories)
    const datasets = [];
    let append = 0;

    for (let i = 0; i < categoryTitles.length; i++) {
        const title = categoryTitles[i];
        const info = categories[title];

        datasets.push({
            label: title,
            data: [info.earned + append],
            borderWidth: 1,
            backgroundColor: info.color,
            borderColor: 'transparent'
        })

        append += info.earned;
    }

    const configuration = {
        type: 'bar',
        data: {
            labels: [''],
            datasets: datasets
        },
        options: {
            indexAxis: 'y',
            plugins: {
                legend: {
                    labels: {
                        color: font_color // key label color
                    }
                },
            },
            scales: {
                x: {
                    grid: {
                        color: tick_color // tick line color
                    },
                    ticks: {
                        stepSize: 1,
                        color: font_color, // tick label color
                        callback: function (value) {
                            const grade = Object.entries(thresholds).find(([key, val]) => val === value);
                            return grade ? grade[0] : null;
                        }
                    },
                    max: Math.max(...Object.values(thresholds))
                },
                y: {
                    grid: {
                        color: grid_color // grid line color
                    },
                    stacked: true
                }
            }
        }
    };

    const image = await chartJSNodeCanvas.renderToBuffer(configuration);
    fs.writeFileSync(output_file, image);
})();