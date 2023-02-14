const { ChartJSNodeCanvas } = require('chartjs-node-canvas');
const fs = require("fs");

const width = 400;
const height = 100;
const backgroundColour = 'transparent';
const chartJSNodeCanvas = new ChartJSNodeCanvas({ width, height, backgroundColour });

(async () => {
    const dir_path = process.argv[2]
    const meets_expectations = parseInt(process.argv[3])
    const progressing = parseInt(process.argv[4])
    const progress_threshholds = JSON.parse(fs.readFileSync(process.argv[5], "utf-8"));

    // determine the student's next grade
    let nextGrade
    for (const key in progress_threshholds.meets_expectations) {
        if (meets_expectations > progress_threshholds.meets_expectations[key])
            break
        nextGrade = key
    }

    // determine how many Ps should be counted towards student's next grade
    let countedP = progress_threshholds.progressing[nextGrade] - progress_threshholds.meets_expectations[nextGrade]
    if (countedP > progressing)
        countedP = progressing

    const configuration = {
        type: 'bar',
        data: {
            labels: [''],
            datasets: [{
                label: 'M or Better',
                data: [meets_expectations],
                borderWidth: 1,
                backgroundColor: '#a5b899',
                borderColor: 'transparent'
            },
            {
                label: 'Counted P',
                data: [meets_expectations + countedP],
                borderWidth: 1,
                backgroundColor: '#d3c0a3',
                borderColor: 'transparent'
            },
            {
                label: 'Total P',
                data: [meets_expectations + progressing],
                borderWidth: 1,
                backgroundColor: '#d3717d',
                borderColor: 'transparent'
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
                        callback: function (value) {
                            mArray = Object.entries(progress_threshholds.meets_expectations)
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
                                    return newArray[i][0].split('').join(' ').toUpperCase()
                            }
                        }
                    },
                    max: progress_threshholds.total
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
    fs.writeFileSync(dir_path, image);
})();