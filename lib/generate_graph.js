const { ChartJSNodeCanvas } = require('chartjs-node-canvas');
const fs = require("fs");

const width = 400; //px
const height = 100; //px
const backgroundColour = 'transparent'; // Uses https://www.w3schools.com/tags/canvas_fillstyle.asp
const chartJSNodeCanvas = new ChartJSNodeCanvas({ width, height, backgroundColour });

(async () => {
    LearningObjectives = { A: 10, CB: 9, D: 8, total: 11}
    Homework = { BA: 10, DC: 9, total: 11 }

    const github = process.argv[2]
    const category = process.argv[3]
    const passed = process.argv[4]
    const progressing = process.argv[5]
    const attempted = process.argv[6]

    if (category == "LearningObjectives")
        grades = LearningObjectives
    if (category == "Homework")
        grades = Homework

    // Object.entries(grades).forEach(grade => 
    //     console.log(grade)
    // )

    const configuration = {
        type: 'bar',
        data: {
            labels: [''],
            datasets: [{
                label: 'M or Better',
                data: [passed],
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
                            gradeEntries = Object.entries(grades)
                            for (let i = 0; i < gradeEntries.length; i++) {
                                if (value == gradeEntries[i][1] && gradeEntries[i][0] != 'total')
                                    return (gradeEntries[i][0]).split('').join(' ')
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
