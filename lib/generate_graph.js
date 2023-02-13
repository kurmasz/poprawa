const { ChartJSNodeCanvas } = require('chartjs-node-canvas');
const fs = require("fs");

const width = 400;
const height = 100;
const backgroundColour = 'transparent';
const chartJSNodeCanvas = new ChartJSNodeCanvas({ width, height, backgroundColour });

(async () => {
    const path = process.argv[2]
    const mastered = parseInt(process.argv[3])
    const progressing = parseInt(process.argv[4])
    const grades = JSON.parse(fs.readFileSync(process.argv[5], "utf-8"));

    // determine the student's next grade
    let nextGrade
    for (const key in grades.mastered) {
        if (mastered > grades.mastered[key])
            break
        nextGrade = key
    }

    // determine how many Ps should be counted towards student's next grade
    let countedP = grades.progressing[nextGrade] - grades.mastered[nextGrade]
    if (countedP > progressing)
        countedP = progressing

    const configuration = {
        type: 'bar',
        data: {
            labels: [''],
            datasets: [{
                label: 'M or Better',
                data: [mastered],
                borderWidth: 1,
                backgroundColor: '#a5b899',
                borderColor: 'transparent'
            },
            {
                label: 'Counted P',
                data: [mastered + countedP],
                borderWidth: 1,
                backgroundColor: '#d3c0a3',
                borderColor: 'transparent'
            },
            {
                label: 'Total P',
                data: [mastered + progressing],
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