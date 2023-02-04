const { ChartJSNodeCanvas } = require('chartjs-node-canvas');
const fs = require("fs");

const width = 400;
const height = 100;
const backgroundColour = 'transparent';
const chartJSNodeCanvas = new ChartJSNodeCanvas({ width, height, backgroundColour });

(async () => {
    const path = process.argv[2]
    const mastered = process.argv[3]
    const attempted = process.argv[4]
    const grades = JSON.parse(process.argv[5])

    const configuration = {
        type: 'bar',
        data: {
            labels: [''],
            datasets: [{
                label: 'M or Better',
                data: [mastered],
                borderWidth: 1,
                backgroundColor: '#4774c9',
                borderColor: '#063970'
            },
            {
                label: 'Attempted',
                data: [attempted],
                borderWidth: 1,
                backgroundColor: '#688fd9',
                borderColor: '#38548a'
            }],
        },
        options: {
            indexAxis: 'y',
            plugins: {
                legend: {
                    labels: {
                        color: "#A9A9A9",
                    }
                },
            },
            scales: {
                x: {
                    grid: {
                        color: '#A9A9A9'
                    },
                    ticks: {
                        stepSize: 1,
                        color: '#A9A9A9',
                        callback: function (value, index, ticks) {
                            mArray = Object.entries(grades.mastered)
                            newArray = []

                            // combine letter grades that share the same M requirement
                            for (i = 0; i < mArray.length; i++) {
                                if (i == mArray.length - 1) {
                                    newArray.push(mArray[i])
                                    break
                                }

                                if (mArray[i][1] == mArray[i + 1][1]) {
                                    newKey = mArray[i + 1][0].concat(mArray[i][0])
                                    newArray.push([newKey, mArray[i][1]])

                                    if (i + 1 == mArray.length - 1)
                                        break
                                    else
                                        i++
                                } else {
                                    newArray.push(mArray[i])
                                }
                            }

                            for (i = 0; i < newArray.length; i++) {
                                if (value == newArray[i][1])
                                    return (newArray[i][0]).split('').join(' ')
                            }
                        }
                    },
                    max: grades.total
                },
                y: {
                    grid: {
                        color: '#A9A9A9'
                    },
                    stacked: true
                }
            }
        }
    };

    const image = await chartJSNodeCanvas.renderToBuffer(configuration);
    fs.writeFileSync(path, image);
})();