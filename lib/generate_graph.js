const { ChartJSNodeCanvas } = require('chartjs-node-canvas');
const fs = require("fs");

const width = 400;
const height = 100;
const backgroundColour = 'transparent';
const chartJSNodeCanvas = new ChartJSNodeCanvas({ width, height, backgroundColour });

(async () => {
    LearningObjectives = {
        mastered: { A: 10, B: 9, C: 9, D: 8 },
        progressing: { A: 11, B: 11, C: 10,  D: 9 },
        total: 11
    }
    Homework = {
        mastered: { A: 10, B: 10, C: 9, D: 9 },
        progressing: { A: null, B: null, C: null, D: null },
        total: 11
    }

    const github = process.argv[2]
    const category = process.argv[3]
    const mastered = process.argv[4]
    const attempted = process.argv[5]

    if (category == "LearningObjectives")
        grades = LearningObjectives
    if (category == "Homework")
        grades = Homework

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
            scales: {
                x: {
                    ticks: {
                        stepSize: 1,
                        callback: function (value, index, ticks) {
                            
                            mArray = Object.entries(grades.mastered)
                            newArray = []
                            
                            for (i = 0; i < mArray.length; i++) {
                                if (i == mArray.length - 1) {
                                    newArray.push(mArray[i])
                                    break
                                }
                                
                                if (mArray[i][1] == mArray[i+1][1]) {
                                    newKey = mArray[i+1][0].concat(mArray[i][0])
                                    newArray.push([newKey, mArray[i][1]])
                                    
                                    if (i+1 == mArray.length - 1) 
                                        break
                                    else
                                        i++
                                } 
                                else {
                                    newArray.push(mArray[i])
                                }
                            }

                            console.log(newArray)
                            
                            for (let i = 0; i < newArray.length; i++) {
                                if (value == newArray[i][1] && newArray[i][0] != 'total')
                                    return (newArray[i][0]).split('').join(' ')
                            }
                        }
                    },
                    max: grades.total
                },
                y: {
                    stacked: true
                }
            }
        }
    };

    const image = await chartJSNodeCanvas.renderToBuffer(configuration);
    fs.writeFileSync(`test-data/progressReports/${github}/${category}.png`, image);
})();