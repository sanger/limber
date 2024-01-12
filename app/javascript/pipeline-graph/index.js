// Mounts #graph and renders a summary of the limber pipelines source from
// pipelines.json

import cytoscape from 'cytoscape'

// Distinct colours as used in the rest of limber
const colours = [
  '#FFFF00',
  '#1CE6FF',
  '#FF34FF',
  '#FF4A46',
  '#008941',
  '#006FA6',
  '#A30059',
  '#FFDBE5',
  '#7A4900',
  '#0000A6',
  '#63FFAC',
  '#B79762',
  '#004D43',
  '#8FB0FF',
  '#997D87',
  '#5A0007',
  '#809693',
  '#FEFFE6',
  '#1B4400',
  '#4FC601',
  '#3B5DFF',
  '#4A3B53',
  '#FF2F80',
  '#61615A',
  '#BA0900',
  '#6B7900',
  '#00C2A0',
  '#FFAA92',
  '#FF90C9',
  '#B903AA',
  '#D16100',
  '#DDEFFF',
  '#000035',
  '#7B4F4B',
  '#A1C299',
  '#300018',
  '#0AA6D8',
  '#013349',
  '#00846F',
  '#372101',
  '#FFB500',
  '#C2FFED',
  '#A079BF',
  '#CC0744',
  '#C0B9B2',
  '#C2FF99',
  '#001E09',
  '#00489C',
  '#6F0062',
  '#0CBD66',
  '#EEC3FF',
  '#456D75',
  '#B77B68',
  '#7A87A1',
  '#788D66',
  '#885578',
  '#FAD09F',
  '#FF8A9A',
  '#D157A0',
  '#BEC459',
  '#456648',
  '#0086ED',
  '#886F4C',
  '#34362D',
  '#B4A8BD',
  '#00A6AA',
  '#452C2C',
  '#636375',
  '#A3C8C9',
  '#FF913F',
  '#938A81',
  '#575329',
  '#00FECF',
  '#B05B6F',
  '#8CD0FF',
  '#3B9700',
  '#04F757',
  '#C8A1A1',
  '#1E6E00',
  '#7900D7',
  '#A77500',
  '#6367A9',
  '#A05837',
  '#6B002C',
  '#772600',
  '#D790FF',
  '#9B9700',
  '#549E79',
  '#FFF69F',
  '#201625',
  '#72418F',
  '#BC23FF',
  '#99ADC0',
  '#3A2465',
  '#922329',
  '#5B4534',
]

let cy = undefined
const pipelineColours = {}
const filterField = document.getElementById('filter')

const pipelineColourEdge = function (edge) {
  var pipeline = edge.data('pipeline')
  return pipelineColours[pipeline] || '#666'
}
const calculatePipelineColours = function (pipelineNames) {
  const coloursCopy = [...colours]
  pipelineNames.forEach((pipeline) => {
    const colour = coloursCopy.shift()
    pipelineColours[pipeline] = colour
  })
}

const renderPipelinesKey = function (pipelineNames) {
  const key = document.getElementById('pipelines-key')
  key.innerHTML = ''
  pipelineNames.forEach((pipeline) => {
    const item = document.createElement('li')
    const pipelineColour = pipelineColours[pipeline] || '#666'

    item.style.borderLeft = `solid 10px ${pipelineColour}`
    item.textContent = pipeline

    key.appendChild(item)
  })
}

// Polygon dimensions represent a series of points defined by alternating x,y co-ordinates
// They are bounded by the top left (-1,-1) and the bottom right (1,1)
// The polygons here begin with the upper left most position, and proceed round the shape
// clockwise
const platePolygon = '-1 -1 0.9 -1 1 -0.9 1 0.9 0.9 1 -0.9 1 -1 0.9'
const tubePolygon = '-1 -1 1 -1 1 -0.9 0.9 -0.9 0.9 0.75 0 1 -0.9 0.75 -0.9 -0.9 -1 -0.9'
const bg384 =
  'data:image/png,%89PNG%0D%0A%1A%0A%00%00%00%0DIHDR%00%00%00%2C%00%00%00%13%10%06%00%00%00%BB83%3A%00%00%12SzTXtRaw%20profile%20type%20exif%00%00x%DA%BD%9Ag%B2%1B%B9%15%85%FFc%15%5EB%23%03%CBA%AC%F2%0E%BC%7C%7F%07%20_%904%D2%B8%EC%F2%E3%88%A1%D9D%037%9C%80%1E%B3%FE%F5%CFm%FE%C1_%A8%A5%98%10sI5%A5%87%BFPCu%8D7%E5%B9%7F%ED%3C%DB%27%9C%E7%F3%E7%C6%EB%3B%FB%FD%B8%B1%FE%F5%85%E3%90%DE%BF%3E%97%F4%3A%BE8%EE8%DF%BD%8E%BF%06%B2%8D%E3%F1%CB%40u%BD%BE%E8%DF%BFh%AF%81%5Cy%5D%E0u%FC%7D%21o%EF%05%9E%D7%C0%A6%BD%06%F2%EEu%E5p%3F%F7%BB%AC%27%D5%92%BF.a%BC%CE%DF%AF%EFO%18%F8g%F4%14%7Cv%29%26%9B%03%CF%C1%3D9%A7%CA%FB%E2%9E%90%89%DB%D4D%F7pU%BF%8B%FD5%D0%0F%9F%CD%FBT%C7%9C%DC%F2%84%8C%E7%A4%19z%A6%EF%ABo%3A%C63%9F%9C%8E%A4s%C4%9D%E7zgJ%B6%9Cy2%EF%EB%3B%AE%BF%FF%FB%DD%CC%CD%7B%EA%AF%94%7FK%E9%C7%BB%1FR%9D%D6%CF%996%E7%8B%F7%29%FE%87%0C%A5%8F%D7_%1E%B7%F1%F3%B8%F9%9A%D2%93%B7%AFWN%AFw%EE%FB%F1g%BF%AB%EA3s%E6%9D%BE%BDg%D9%7B%DD%D5%B5%90Xrz-%EA%BD%C4%F3%8E%F3%BA%A2u~%95xd%FE%C5%A7%28%D8zT%1E%85%96%18%D4%D1%A4%C8%3A%8Fa%ABu%A4l%DB%60%A7mv%DBu%5E%87%1DL1%B8%E52%AF%CE%0D%E7%ED0%1C%2C%24%A3%BAq%D2%1D%F4%B0%DBe%12%3F%7D%21%CD%83r%F0%1Cu%1Fs%B1%E7%B2%F5%5Cn%D8%C2%85%A7-%86%EA%B1%0C%A6%CA%F8%AF%1E%E6%EF%9C%B4%B7%1A%CAZ%C52%AD%13%2B%E6%E5%14pf%A1%CCYk%1E%CBid%C4%EEWP%E3%09%F0%FB%F1%E3%9F%F2%EA%C9%60%3Ca.%2C%B0%3D%5D%23%90%FE%1E%EDgq%F9%93h%CF%89%91%D7%DB%C06%CF%D7%00%84%88%19D%26c%3D%19x%92%F5%D1%26%FBd%E7L%B6%96%40%16%12%D4%98%BA%F3%C1u%D2bct%93I%BA%E0%7D%229t%01%D7%E67%D9%9ES%5Dt%F70%40H%22%A2O%C6grCk%92%AC%10%22%F5%93C%A1%86Z%F41%C4%18S%CC%B1%C4%1A%5B%F2I%1D%96RNB%D4%96%7D%0E9%E6%94s.%B9%E6f%8A%2F%A1%C4%92J.%A5%D4%D2%AA%AB%1E%C4%8D%95~%AC%A5%D6%DA%1A%17m%8C%DC%F8u%E3%84%D6%BA%EB%BE%87%1E%7B%EA%B9%97%5E%7B%1B%CE%0C%3F%C2%88%23%8D%3C%CA%A8%A3M7%FD%A4%8Fg%9Ay%96Yg%5BvQJ%2B%AC%B8%D2%CA%AB%AC%BA%DA%A6%D4%B6%DFa%C7%9Dv%DEeW%B3%DBG%D6%5Ei%FD%E9%F1%1Fd%CD%BE%B2%E6N%A6tb%FE%C8%1AGs~%0Fa%05%27Q9%23c.X%12%9E%95%01%EB%8Ds%CA%D9Sl%08N%99S%CE%9E%EA%E8%8A%E8%98dTr%A6U%C6%C8%60X%D6%C5m%3Fr%F7%99%B9h%80%CE%FFI%DE%0C%89p%FF%8B%CC%19%A5%EEod%EE%E7%BC%FD%2Ak%B3%1D%A2%F3%27CjC%05%F5%F1t%1F%275W%F8%0F%C6%FC%F5%AB_%AE%00%98%99%3A%EA%DB%C2%FFD%86Km~%1C%C7t%7D%8D%9A%BA%0B%CD%F1%DD%EE%C4%0E%FA%18%C5%85G%28%E6%A7%0D%7B%C58%3A3%F6%FAM%0F%26%E7%3D%AA%1F%FA%BC%06%7D%A6%C3%8B%28%A4%BE%92DD%A7%C1%C8%87m%2C%C7%A7%C9%87lw%ADD9%3A%F2%03%B5%AF%87tuC%C5%91%A8%0D%21%86%B2z%9C%23%8BC%DD.%25%EF%1D%1Ck%236%93%9A%E3%02v%B4%C5%D7O%DD%DBE%B8%D6G%1DM6%F6%B8%CD%06%85%BBB6%9F%27%9F%F9%3C%3D%870C%1E%BE%EEg%F9P%A7%CB%91%DC%EC%EE%E7%0Ev%E5%5C%ABM%3B%E6%D9%7B%A3%16%18%BE%BA%C7l%20f%3D%93%CF%21J%40%C4%1F_%F3%D87%0A%93%C9%90%D1%7D%F2t%8E%B0%7C%08c%9F%28%99R%FB~F%DFK%91%D8%E9Lv%04N%EF%9E%A0%D9%95h%A4%DEs%ED%7D%E75%CER%26%85%3D%EB%DA3%29i%81%FC%21%5D%CC%B6%1D%C9%C6%8F%EC%B36X%B8S%B1%3B%8D%DDS%9E5s%85%A9%1F%D7H%0D%AD%A90%EC9%A95%AE%8A%9A%D8%A9%A9%AET%0B%E6%7BQ%CC%E1%99%1A%E1%9E%DBV%2A%9F%2A%F1%8B%F6%E9%A9%CD%E6%19z%8D%F4l%DF%C7%A8y%A1%19%3A%83O%B4TY%C6Fe%BF%3E%BE%D8%B8C%A6B%A2%D4V%3C%AFy%0CK%15%9D%12%09%FE%96%08%1D%7FKdR%22%23%AF%3E%8Bg%19%86%1A%AC%AE%E4%96%C5%D9t%94N%9A%B6%BB%99%CBI%A42O%85%3Fu%EE%A2%81J%EA%F39%E1%7F%12%24%AC%EFl%0Cy%9B%01%DA%AC%7B%A0%D9%B6%03%27%C3%9E%E3%0C8%229%0Bwn%19%9C%1C%DB2%5CU%40%3DW%F2%24%A4%8F%98%5Bc%0EF%0D%A0%8E%24%21%84W%B5%E9H%D3%F6%B6%A75%06%20%93%90qe%90%A8F%AD%EE%12%D6%1E%E9%2C%0E%F2X%BD%EA%5D%F1%96%EE%E7%CBvb%DF%B4%F0s5%BA%8F%BA%86%D2%B3%2Ay%3D%23Q%04%CB%B5N%D3CQ%BBtO4%03%A5Mj%98%16%29yL%B7%BD%CF%B8%C2%F4%2C%D0%C3x%99%3A%A5%29%DCS%0A%D50z%9D%03%A8%B2%A5%8E%ED%D1%2133%A1%B8%A8%91%27P%7D%81%12%28%14_%A2%8E4%B9%16%D4%3D%846%EFw%C2%CA%C9%CD%B4%A7%8E%5C%D8%3E%DC%0A%7F%CE%12A%BA%D8v-%E0D%15%0Ey%A3Q%EBJg%AD%9Bk%95s%3A%90K%03%8A%B9%9F%AC%16%0A7%B7%CB%B6%D7%60%B3%29%83%93%C1%3A%15%B0N%AF%B9%5B%25%9B%90%10%FDH%07%9C%A1%28A%E5%FE%B4%DB%C9%AA%CDk%2F%266v%89%E0%EA%5C%40%F9%1C%1B8%A6%B2%AA%A1d%D0%B7%81%2C%B5%95r%21%0A%FEY%24%CF%3A%BFm%5B%CBu%F2%89%F2%3E%E5P%9D%9DT%27%E5%7C%E7%DD%90%DB%2C%A4%92%23%F3WI%22%3E%AE%9D8%7Dd%FC%9Doe%FB%94%E9%D7t%9B%BF%CE%F7%19%0A%A0%E8%BB%3CQ%DD%16%1B%AB%A2%13%DB%82%A8%26%D5%B7v%CBq%86%05%12W%E3VK%A9%C6%E2v%85q%07~%2C%D0%DB%A1%FA%B23%08Hr%0E%2Cw_%EE%E2%40%E5%E0%0F%2A%13%5Bf%C3%83%5E%2F%B7%FB%CF%3A%81%96w%24%E2%FA%16%89%BA%BC%D0%8B%FEyv%B9%BD%E7b%06%96O%06%B3%BA%14%16%01%A8%C7%5E%2F%24%E9%B5%85U%BBO%DD%93%16%F8%2B%27%2A%89%15%E5%0E%BF%CF%3E%D2t%28f%D4W%976%40Nz%88%90%E0%05%04%7BB%DE%84%A5%00%00F%91%FA%02%09%00%99%CD1%D2%DB%7C%27%CB-%A6%A7W%11%04T%9F-%10M_%D2%AE%D3%E6%FDD%0F%1D%24%A3%A2%29i%8A%1D%5CD%91%87%E2%B5%268S%60%DB%03%03%82%B7h%B2%15%07%D5%01%85%D34%FC7%D7%AC%84%0B~%A8%9Dt%25%D3%27%BC%04%A4%C0%CF%A2%F48%B54%AAh%22%D8%7B%A3%82G%01%05l%E9%B0ZX%8B%06%2A%A8rJ%93HR%C7%1F%2Ca%DEo%2C%0D%91ok%89%B3%C2i%19%22%11N%9D3J%94L%A3E%1Fu%D6iW%BB%5E%8D%F5Pp%E6%B6%C3%E8q%F9%FD%8D%8D%E0%3A%BB%A9%8AAk%40%81%ED%E0G%3Er%82X%A2e%A7%1F%F0Z%EC%00%B5%0B%D5%24%D4%16I%00%26%82%3EG%1D%DD%BE%B69nU%5B%B0%E3%5C7%B8%96%C4%BE%C5%ADrfY%AA%CA%A6%08%00%40h%23%2A%22%5E%F8%1F%87%FF%81%92%08%C1%03D%85%DA%E3%93%D1%11%9D%8E%E8%A3%94%E4%E6D%00%09%9A%D0%8E%60%2A%FAlQ%AC%F4vf%892~d%B4%F8%CB%0C%94%FE%C5%EF%27%BE%20%1EmO%E2Q%F9%B3QG1%C1%B36d%5C%11%DE%0F%B5%E0%0B%BD%82%0E%2B%C6%CA%F8Y%99%16%C12T%E8%DE%B5n%F7%3B%AC%BF%C1%AB%84%86%8B%CB%C5i%28%F5%DAs%ECy%A2%19YQ%DBM%00%B4%BA%9DH6%3F%1A%FA%94l%84%071%9A2%93%80%84k%1B%FD%22%FC%A721_%A5%C9%A72A%8AX%A1%C2%E2%02%DE%0FrO%5DL%CD%8DbG%09%22r%0F%C4u%B4J%2B%DD9%B2%06%C5%C2%E5%ACL%7DN%ABZ%60%A3T2%8E%12H%CD%BB%23RE%5D%A0%5C%F3%A5%0C%E8%1A%E6%AA%C9%CB%90%12C%10%F2%F1%CDt%A6E%CF%FAvx%0BIW%E0%B3%3D%A8p%8B%0A%99%A4Q%F3%A0%E3z%9BUm%80%F3%A6wQl%16%60%A5%93%29YP%B9%98%A3%1D%C4%0B%CBVT%ED%ABf%EC%21R%E8%5C%94%3BR%EBH%C7%E5%C8%EE%B9%0A%EF%3D%E1%EC%01%10%A8.W%87%FC5%19%EDT%D0%17%8FC%8A%05%12%9AQ%9CL%B0%5B%D4%C6%86%E8%13%3A%0D%AD%CA%900%9E%C2D%03sU0%88%B5%AE%16F%DA%B5%E5n%5CY%CCM%E9O%B1%94%13-z%EE4%9Fky%B8DI%814%F4%C5%EDlP%06%12%CC%A7%92%22%8D%0DT%82%C3%8D%18%D9D%1E%29%DF%0E%DE%A2%2F%16%18v%E1u%A1%EA%EE%20%60%A9m%60%DA%0E%BD2%0BX%27vTII%A9%03%DA%29Im%18j%C6%A7%D6%CA%905Eb6%28%C0g%B5%A5%24P%86%0F%2C%15G_%A5Y%C6%1A%25%DA%26%E3%10%83%BC%C6%0AX%20%D7%14~%83%AB%2A%AA%D8%F6%C6%16t%1Ap%8D%C8Y%14e%13%7B%3A%E4-%F0%048%ED%88%7DA%1D%D6%8Dp%40%B4Q%FE%C8%BB%CCZ%86A.x%01%2F%BC%DB%24.%912%7F%22%81nUp%B9~%C6%3Ego%80g%3A%BDL%89%04%87%09%D3%B6%C5cUn%EF%B8%C7x%B8a%B7x%B4%BA0%1A%FD%8B%D5%91%12%A0%81%27%1D%86%60%87N%2Ar%BC%C9%2A%2F%FC%D1%8A%18%04%FC%19%EAJ%06%A8g%10%D7Sa%24%2B%8B%7Dn%F4%3A%22%08%A2%E8%C8%08%5C%DEd%09%E6%93%2B%A1%CA%19%9D%F8b%C5%00R%20%3A%0Ec%84E%92%27%A6%0C%2C%090%158Bw%03%29%92%09T%1E%2A%0181%F1%21e%ED%EEQ%1D%EB%3A%12%B5._t%053%11P%EB%01p%03%BA%81%B2%B1%A83k%AB%87%0E%E9%EAq%D7%01%86e%F0%85%00%86%C3O%8D%227%01%E3%60%9E%1C%D1%25%CC%F4%02~%09%FF%26%FD%BE%A9%3CH%05%24%A7%3F%AB%25%06%B3%D2k8%23%AC%05Y%23%E2%C4.%23%A8%14%08i%08%87%E2%973N%CC%85f%18%12%EBA%B2%7D%00%01%0E%E1%B0%1D%96%A0%E0%E9%BAwP1%CF%DE%9A%15%EBAHz%CF%C7%83%83%FD%EC%F3%1C%07%97.%E10%15%B9%8E%F2%E9%1A%7F%26%25sY%E9%2B%29A%7C%3F%C8%7D%C0%F0%0A%FE%0F%B9%FF%D5%8AJK%20%22%8E%7F%7C%C9%3E%D7%5E%B2O%F1%0C%826%04-%CB%3C%24%00%05%D3%E5QR%80%EA%ED%17%2A%D1%40%98S%80.%18%98eJ%C5%3A%AA%3B%9C%22%14%C1%10%87%21%90S%BE%A8%3A%9C%FD%C0WSCcF%F88%27P%06%A3%E5%01%08%8C%0E%F6%F81%24%B6%60%B0%2B%83%E5%E6%ED%85%CB%B9%DE%5C%F2%C1%29Eo%01%26%14R%16%FD%01%1F%CBB%84%89%12g%C9%D9%082T%8Bh9%94O%3A%96%1A%7D%1A%9F%91%91B%C0%CA%08t%00%B2%95n%F6S%BB%A1%27%84%12p%27%84G%BE%D9%E8%8C%F4%DBDb%8D%C9E0sH%C4%0A%DB%1E%18%85%60I%DF%81%EB%E0h%ADZ%B1%DB%B6W%90%84%0B%91%F4j%E1%CE-%0ACD%A8%03%3F%A6%2AW%83G%7C%F4e%87%F6%02%25GpA%00%EBF%AD%C1%85%EF%B3%A4%1B%AE%EC%88%E6%D3%E5%7D%BC%C6kw%D7%BC%9C%E7%1D%0E%7B%F6%F9%B2%14bPw%5D%91%F5H%0A%40%10%20%B6%86%0B%CB7%AB%AA%E4d%1D%CC%01%98%E5%E9%02%98%CBR3%1A%2FA0P%01%90U%85%E5%16%2A%96%AF%00R%CE.A%82%60%80%11%3BUT%94%02%0D%15%B1%F4%1B%D9%8A%DC%1F%B8z%22F%F0%89%89%C6%199.%90%98q%E0%21%90%A3k_%80%BC%E19%5CF%1F%DD%8D%01%AC%C3%0A%BBf%903%9D%8D%01%1B%80%B6n%D1J%88%26L%98%D8%00%DC%95kV%0F%22%C1K%F1w%8Ctv%16L%C0%AFa%CA%E4%99%BDd%E8h10%E5u%E6%0E%22PC%B8%3Bt%A8%15%9B%114%A96%1FN%FCqF%BBR%9D%20%C02%E9%20B%F2%AE%94%8E%98%EE%B8%8C%5EY%8A%C0%E4cwB%B8L%A6%28%8B%BB%E9%D1%EE6%83j%05%B1%99%C0%F0N%FAW%0Fh%A9%EDU%FAgH%E8CC%DA%CF%21%E3%29h%F0e%A6%2C%C2~%80%0EU%09M%222%89.5%F3TpcK%40~%A9%E6%A7%AC%86.t%F2%88%9E%C6%7C%0DA%9F%82%7B%19%A6%8A%88%BE%97%3AA%B0%EDEe%07x%1D%A6y%BC%F6%98%97%14%89%2C%D8%C8M%3B%29%B3%8A%E7%D3%D5k%3D%07i8%CA%40%7Dr%E5%B3%A0%8B%B3%01%AF%23%8F%0F~%FD%19%BDt%E6s%3D%DC%FE%09%BC%CCo6%2B~%B5%B1%C6j%D6%D9Ep%1F%F2%C6%E78%3A%F2x%5D%7D%93%07%F6%A2%82%15W%DE%A0%0F%11%A6%927DT%9BiG%9FP%9F%94%818%E1%CC%CB%5E%7C%84%CE%A5%8F%E8%D0Y%B4%BF%A32JE%9E%85j%B6%05%F8C6%0E%8F%8A%98%ADc%AC%F7K%D9%DE%3D%26%C1%A5%D8%5C%C8NGL%F3%BC%B6%AD%FE%80%D3%C4%E8%A4p%A7%F2%EBm%19%D3%1DhE%9D%80%DF%02WK%C7%26%AA%26%89Iw%9Ag%27%91%B8%1F%25%2B%3A%C7%81V%B4-%05%87V%A3%8B%06b%10%A1%B6%8C%07W%8F%DB%FB%D8%CF%C3%8A%BC%F7%F3%9EvE3%8Ah%3E%07a8K%7B%60R%A8%28%80~s~%E9%A8E%D1%A5T%FA%89%01%8AUS%0F%BE-%DDQ9%A7%82%1E%21%1F1%F8a%CAp%8A%92%85%B6%AD%A3%E8%B65o%C7%17%A0%8Ao%86%AF%B9%EE%91%FB%0A%11%B2%B0%82%06O%C9%7D%7F%CA%C2%3B%08%AE%5B%B20%1A%8F%FD%A1%BB%10%CDN%BA0c%C0%40%E4%98%1C%A1%8E%DD%C9%273K%AB%CE%C0%FAQ%3F%5Dj%82%ECD%FA%BE%0FQO%98%88C%83%91F%1F%8E%F9%84.%C1%F8%20%60%22%C8%A2%C9%B4%D6%8B%25%3Ag2%28%A5v%B6%CAJ%0E%91%0A%E0%A2%D1a%C5%80Iff%1Bt4%DC%E0%B22%BB%01%92p%7Cz%0A%FD%BB%8A-%E5%CA%23%97g%20%00%F1%17%F8%FE%F1j~%FD%85%B6%D6%0E%F2%C8%CB%A1%FE%8F%93%CB%2A%19%1CS%BE%C0%1F%84%D7%0F%C2%F28%3C%D3%2C%F6%EA%D8N%CC%ABvDG%B8%DB%3Dg%B8%07a%80%B4%C2%98%06%94%9A%EE%EA%C0%F5%DBj%FF%5D%AC%16Z%D7%CD%D3%E2%9Eb%FC%E0e%E3%F9%CA%EA%14%3C%3F8J1%9E%1D%95%A6%E2GQ%ECH%EDVD%21%ACT%F1%C7%08%20%97%88%04AG%BC%A1%8A%02%3A%1B7wBpwi%91%CA%FB%AE%C5%891%5E%1B%ACw%93g%DE%1D3%8A.%BD%BC%C5%A2%18%00%13%E0%3B%99%05%17%A0j%22z%B39m%28%7B%CC%1C%84F%FA%12%10%08%1E%BB%12j%02%1C1%DC%5D%FB%14%BD%60m%25W%BE%5D%D4%FCtUmx%A0%A0%91%BCib%AF%1De%85%93%C9%DA.%0D%3B%91y%00%7B%14V%EA%F0%B5%8EZw2%AA%DE%14%84BP%D1%B3%E8%8A%C3%2C%A2%2FF%95g%88%11%7D%81g%28%D71%00%A4r%0C%09%CD%3C%D1%C1%BC%801%8A%0A%06%85%F4_%B2%FF%E3v%06%DD%01%ED%C3%25d%F6A%FCB%21%DF%3A%CB%C0%9D_%5B%0B4%FB%B1%B5%04U%08%27%AA%B6%C1%B1%40C%94Sh%AC%97%A2%92f%07Q%2A%C1%1E%B0Ci%0D%B5%E8a%FB%90fJ%DA%F4%05%BF%20%3C%3A%3ED%A9tZK%B6y%97p%3D%98%20%10%8D%D3%CE%CE%3Fl%B2%CCLb%15%3E%22%220%E6c%3B%E2M%9C%21%C6%AC%EDD%90%1D%8B%24aJ%EA%D11%A2%145%DA%D9f%E3e7%D2%DE%D74%FA%3F%09%E8%7BP%BD%8B%7B%F1N%DA_gZ%B8%3C%87F%E8%28%0A%CA%1B0%91%F9%AC%B2O%CC%2F%05%DCjv%F9j%24%CA%D2%9A%DB%0AN7P%0A%D5%9C%D0%B1%11%B4%ED%09%D18%93%5DL%0Bb%00%03%80%8F%A8m%C6%B1%7C%C6%87%0D%DD%F5%DA%11_%BB%E3%8E%DA%18gi%05%BB%89U%0F%0F%F3Es%8D%8A%94%B0%25%0B%AC%91%1BH%27%24W%1C%92%60%5B%EC%D2%BE%B0%CBPA%CA%E8%9B%BB%E7I%FEN%0F%CB%E9%CF%E3%F4e%26%DB%0ESwW%E0%BD%A4%1A%C5%1CO%BF%EE%3Efp%AA%97%A6%E5S%28%A3%18%2A%D4%86%B3%0B%F8Pu%CB%DD%ADPW%17H%E7O%96%D2%D6E%25%CA%A9%1A%EC%89%1C%2F%92%1A%3A%87%92%1Ee%A8o%07%8B%88TF%94%B6%E3R%848%21y%8A%AA%0E%F8%5B%D4%DE%D9%80%C7U%83%02%8B%19%D6%F6%D4%84%05%9E%13%BDF%9C%8EY%A7%7D%8C%03%08%DC1%EB%C8%0F%ED%97%07%D2X%106%0E%94%ED%B94%A0%13%1Fp%40%3DH%C3%11%CF%12%239%3A%FF%DB%82%D7%F6%13%A26%1A%F7%A1%89%29%94%7D%EEI%08%F2tGBx%A7%3B%12%F3%7DGb%3A%99%B9%A3%B9%28N%F9%C9%C2%2A%90%F6%A8a%C3%0C%8F%A3%BC%5B1%A5%A1%015G%B0%C2z%A7-%88%92%13d%ED%24t%DA%F3%D7%DB%D2%E6%B5%2F%FD%FB%BB%0Fu%B7%FF%FB%40%88%7F%20%08%B8%A4%3B%7C%BC%20%17%AA4%7C%8F2%F8%F2%03K%FB%FCgg%0B9%81%2A%DC%BA%C3%0B-%2C%A0%D2%9A%89w%02%2A%D6%91%85%7F%D3%D1%D2%1Bew%ED%F5%E5%8E%5E%B7%A8%DEi%8E%12%99%A08%00%E4%01IX%96%E2%90%F0%B4%AER%8B%29%9E%92%85%2Ae.%BDz~%E8V%C6%8F%810_%22%81%29%B9%3A%EA%ECF%1E%25%85%84%BAZ%EA%DB%0D%AE%EB%7B%BF3%AB%F9r%20%22%5B%F2K%D6%F4%F9M%D6%F8%21YS%B8%DE%17%A3%9B%2A%DD%064U%ED%09%9A%86p%848%03L%84%D6%A4%8E%00G%DD%AA%FFbrq%2A%D7%D8%BEw0%B5%E7%FF%BA%BB%FA%DA%C0%84%B2%BF%ECa%3E%97%F6%99Q8%AAkXw%97%89%EA%B2%F2~%A8yi%AE%AA%7BP%3F%DE%405w%EF%9AfPp%B4%E5%98%8B%D4%3E%EA%28%9F%2B5W%9B%EE%0D%C9i%FF%9D%BB%10%BF%BE%EF%FD%1F%D8%08sK%E6%BF%B7%11%E6%0F%F7%3C%19L%93%E2%8A%FF%06a%8A%93%A9%B3%A8%EF%80%00%00%00azTXtRaw%20profile%20type%20iptc%00%00x%DA%3D%89%C1%0D%800%0C%03%FF%99%82%11%1C%27%82v%1D%D2%0F%3F%1E%EC%2F%DCJ%60%CB%92%ED%B3%EB~%CA%B6%A5%A4EKf%CF%81%94%7F%F9%F0%02%E3Pm%C1%40xt%05%B3-R%22%A7%9E%5D%E1%A4%C6%F1M%C0%5E1%11%14%DA%A6%1F%E5%05%00%00%0FXiTXtXML%3Acom.adobe.xmp%00%00%00%00%00%3C%3Fxpacket%20begin%3D%22%EF%BB%BF%22%20id%3D%22W5M0MpCehiHzreSzNTczkc9d%22%3F%3E%0A%3Cx%3Axmpmeta%20xmlns%3Ax%3D%22adobe%3Ans%3Ameta%2F%22%20x%3Axmptk%3D%22XMP%20Core%204.4.0-Exiv2%22%3E%0A%20%3Crdf%3ARDF%20xmlns%3Ardf%3D%22http%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23%22%3E%0A%20%20%3Crdf%3ADescription%20rdf%3Aabout%3D%22%22%0A%20%20%20%20xmlns%3AiptcExt%3D%22http%3A%2F%2Fiptc.org%2Fstd%2FIptc4xmpExt%2F2008-02-29%2F%22%0A%20%20%20%20xmlns%3AxmpMM%3D%22http%3A%2F%2Fns.adobe.com%2Fxap%2F1.0%2Fmm%2F%22%0A%20%20%20%20xmlns%3AstEvt%3D%22http%3A%2F%2Fns.adobe.com%2Fxap%2F1.0%2FsType%2FResourceEvent%23%22%0A%20%20%20%20xmlns%3Aplus%3D%22http%3A%2F%2Fns.useplus.org%2Fldf%2Fxmp%2F1.0%2F%22%0A%20%20%20%20xmlns%3AGIMP%3D%22http%3A%2F%2Fwww.gimp.org%2Fxmp%2F%22%0A%20%20%20%20xmlns%3Adc%3D%22http%3A%2F%2Fpurl.org%2Fdc%2Felements%2F1.1%2F%22%0A%20%20%20%20xmlns%3Axmp%3D%22http%3A%2F%2Fns.adobe.com%2Fxap%2F1.0%2F%22%0A%20%20%20xmpMM%3ADocumentID%3D%22gimp%3Adocid%3Agimp%3Af461d88f-fe0e-40a4-bc7f-72aa71bee4ec%22%0A%20%20%20xmpMM%3AInstanceID%3D%22xmp.iid%3A0cd4fd53-4d1c-4e5d-af62-3e97aba468aa%22%0A%20%20%20xmpMM%3AOriginalDocumentID%3D%22xmp.did%3Afedf5476-c7fa-4ffe-a103-8eb2db36dc5f%22%0A%20%20%20GIMP%3AAPI%3D%222.0%22%0A%20%20%20GIMP%3APlatform%3D%22Mac%20OS%22%0A%20%20%20GIMP%3ATimeStamp%3D%221569942739560637%22%0A%20%20%20GIMP%3AVersion%3D%222.10.6%22%0A%20%20%20dc%3AFormat%3D%22image%2Fpng%22%0A%20%20%20xmp%3ACreatorTool%3D%22GIMP%202.10%22%3E%0A%20%20%20%3CiptcExt%3ALocationCreated%3E%0A%20%20%20%20%3Crdf%3ABag%2F%3E%0A%20%20%20%3C%2FiptcExt%3ALocationCreated%3E%0A%20%20%20%3CiptcExt%3ALocationShown%3E%0A%20%20%20%20%3Crdf%3ABag%2F%3E%0A%20%20%20%3C%2FiptcExt%3ALocationShown%3E%0A%20%20%20%3CiptcExt%3AArtworkOrObject%3E%0A%20%20%20%20%3Crdf%3ABag%2F%3E%0A%20%20%20%3C%2FiptcExt%3AArtworkOrObject%3E%0A%20%20%20%3CiptcExt%3ARegistryId%3E%0A%20%20%20%20%3Crdf%3ABag%2F%3E%0A%20%20%20%3C%2FiptcExt%3ARegistryId%3E%0A%20%20%20%3CxmpMM%3AHistory%3E%0A%20%20%20%20%3Crdf%3ASeq%3E%0A%20%20%20%20%20%3Crdf%3Ali%0A%20%20%20%20%20%20stEvt%3Aaction%3D%22saved%22%0A%20%20%20%20%20%20stEvt%3Achanged%3D%22%2F%22%0A%20%20%20%20%20%20stEvt%3AinstanceID%3D%22xmp.iid%3Ab05cb892-8674-4957-9ac4-8f1ba39dfb6f%22%0A%20%20%20%20%20%20stEvt%3AsoftwareAgent%3D%22Gimp%202.10%20%28Mac%20OS%29%22%0A%20%20%20%20%20%20stEvt%3Awhen%3D%222019-10-01T16%3A12%3A19%2B01%3A00%22%2F%3E%0A%20%20%20%20%3C%2Frdf%3ASeq%3E%0A%20%20%20%3C%2FxmpMM%3AHistory%3E%0A%20%20%20%3Cplus%3AImageSupplier%3E%0A%20%20%20%20%3Crdf%3ASeq%2F%3E%0A%20%20%20%3C%2Fplus%3AImageSupplier%3E%0A%20%20%20%3Cplus%3AImageCreator%3E%0A%20%20%20%20%3Crdf%3ASeq%2F%3E%0A%20%20%20%3C%2Fplus%3AImageCreator%3E%0A%20%20%20%3Cplus%3ACopyrightOwner%3E%0A%20%20%20%20%3Crdf%3ASeq%2F%3E%0A%20%20%20%3C%2Fplus%3ACopyrightOwner%3E%0A%20%20%20%3Cplus%3ALicensor%3E%0A%20%20%20%20%3Crdf%3ASeq%2F%3E%0A%20%20%20%3C%2Fplus%3ALicensor%3E%0A%20%20%3C%2Frdf%3ADescription%3E%0A%20%3C%2Frdf%3ARDF%3E%0A%3C%2Fx%3Axmpmeta%3E%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%0A%3C%3Fxpacket%20end%3D%22w%22%3F%3E%08%7B%CC%BF%00%00%00%06bKGD%004%00%3A%00%40%F2%C2%84%EF%00%00%00%09pHYs%00%00.%23%00%00.%23%01x%A5%3Fv%00%00%00%07tIME%07%E3%0A%01%0F%0C%13%8D_%F5%A7%00%00%00%19tEXtComment%00Created%20with%20GIMPW%81%0E%17%00%00%05%DEIDATX%C3%C5%99kPUU%14%C7%CF%11D%05y%88%96%A2%A3%03%1A7%9F%28OA%06%18%C4WN%9A%99%E18%8C%22C%18%E8H%89M%93%8A%8AVj%89%D84%06%99iF%10f%1A%22%21%8E%1A%23%A2%03%5CLQ%04R%12%C8B%0D%0C%01y%88%DC%7BO%1F%FE%FF%FB%E1%DC%D1%CB%B9r%C1%FD%E5%C7%BEg%EF%BD%F6c%AD%B5%D7%DA%88%92%24I%92d%FD%B5%20%08%82%20Lw%01%E7y%81~e%E0%84%0C%D0%E16%F8%F8e%B0%3A%1C%3C%DB%0F%FC%EEo%B0%BCV%14EQ%14%85%ED%82%C2%82y%0C%3E%8A%DA%92rp%D9H%D0c%12h%CFy%B5PN%D9U%F0X%2B%98q%12l%CC%A2%7CI0S%C1%FC%84%60%D4%02%B4%60%E8o%60%E7%11%F0%B3o%21%B7%21%DF%A0%E3%2A%27P%F3%8D%24%2F%C1%806%97d%3B%ED%5E~%9F%23o%DE%98%0C%86%7F%C0%09yv3%E1~%E0%98%29%60~6%07%1A%024%B7%81%D9%A7%C0%83%3B%C1%DC%F3%60k3%DBG%03W~%00U%D3%CD%BC%B1%16%A0%5B%22xw%99%7C%DD-%0D%E0%2B%D9%86%FD%A9y69%60%BB%13%98E%0D%09%9B%0C%AA%DC%40GW%D0E%04%23%EA%C0%9AY%E0%90%18p%8F%0At%3D%60%7C%FAV%2B%C1%83~%60%20%E7s%C9%0At%2F%06%17%7D%02F%DA%82%AF%B7%81%DE%D4%F4%CBk%D9~%0E%C7%DBF%CBl5%CF6%8F%0E%00%D3%3BA%A7%14%13O%C8%FF8%E8%F9%00%14g%28%3CYk0p%12%F88H~%B2%ABG%18%EF%1F%5C%40%8B%18%0Av%D5%83%1E%E7M%9B%BF_%1D%D8%B9%9C%96%F8%05%18%E0%D63%CD%B5%1D%0F%E6%D9rA%EE%C0%C5%26%A5%1Al%26%13%1Av%0C%BC%F3%8F%5Cp%FCf%E3%FD%D6%A6%B3%21%FBu%CE%A3%2F%3En%9A%7C%A7%7C%F0%5E%A7%5C%FE%F2%FC%E7%5B%CF%C0%080%95%AEQw%11%FC%99%1B%3B3%C5D%17%D1%D3b%BF%08%B4%A3%C9%0AQ%40%E5%02%E3%FD%DA%F4%ED%DF%03%2CxI%F9n5M%BE%F5i9%85%25%40%BD%D6%B4%8D%15cQ%DB%F4%90.%F2%06X%98%08F%C7%81%1D%92%D0%DB%85%26t%87%97%8F%07%8F%92%97LQ%29h%FF%97%F1%FE.g%C1%A6%05%EC%DF%0E%FC1%06%F4Y%C5%85k%9F%E1%A2%C2%C0%18%07%F6%FF%0A%B8%B5%03%1C%1A%A3pc%E3x%D9%EB%C0%27%1C%B7%F2_%D0%F9%AA%81KJ%EE%B1%8B%A0%60%DE%EE%81e%60%E8%EF%E0%96%24%B0%94%03%EB~%01%0B~%05%C7%86%29%F4%E1l%1FY%0DvD%CB%27%FE%28%0D%3C%C4v%DE%A1%9C%17%5D%82%DF%13%B0%9E%1B%DB%FE%16%B8%D8Z%A1%7C%FA%D8%B9%0F%29o%1Ax%DF%97.7%96%ED%2C%7Bi%83-J%40%F5Z%E9%A9E%C3Kj%F7%C7%E0%F0%9F8%A1a%A6%C9%E97%1B%9C%7F%0B%AC%BB%F2ty%ED%8By%B0Q%E0%7F%0C%E7n%F3%00%E6%1E%E5%01%F8%2B%93%EB%C1%0D%BE%17%C3%8D%E2%25%3F%DF%9E%EBX%F1%8CK5%D9L%3EXb8T%B4%1C%3C%97%09%AA%07%81%CDL%04%D6%FB%CA%13%8E%904%D3%1C%8E%9D%3D%B8%F0%04%13%9A%09%60.%E3%E8%23j%FA%ECzpj%02%C3%C6FpP2%13%A2%BD%60%FF%1C%E3%1B%3B%FA%12%C3%AEP%8E%C3%B02%96%E1%E7%A9%5DLTR%85%BE%2A%3C%D1%1A%D0j%0F8%2A%04L%D9JW%F1%06%F8%80a%9B%BB%CE%F8x6%F4%9D%A7%E8%CBu%F4%85%FB_%05%07%85S%23%3Bh%21%D4%B4%15%0C%FC%D5%D48%ED%06%F20%F8%23-%CAf%B6%81%A5T%80%27%3F%A5%05%D6%82%09%EBh%B1%13%14%86%85%8A5X4%CF%C6%0F.B%AD%98%B7%EBDj%F4%F7%0C%D3%22%CA%A1%11R%A6%BC%DF%BA%2A%D4%92%26%82%B5%BC%14%A7%ADA%FB%E6%CCn%C2%A9q%A8md%FF%8D%03h%98%FB%C05%A5%60%0A%A3%14%CBt%F0%06%C7u%0E%A2e2z%D1%F8%2B%5B%B5%E3M%A6%CC%8Cv4-%60%3E%9F%10Z%0F%83%15_%9AY%C3So%CAO%F6%C6%28%D02%DE%C0%B73%05%2F%F4%96%B7%DF%FF%26-%E5%90ir%070%5EU%EF%90%8F%97%97C%CD%ED%E2%3C.3J%D9%24%F5I%B9%B0%DD%D2%BC%8E%A4%8B%3ET%F8%10%18%D0%CE%BA%3E%AEe%CAk%3D%05%1C%E6%2B%EF%DF%94%C4%3F%C6%29%95%08M%EF%7C%0D%0B%BAY%C2%14%9A_G%5E%A7F3%A3%D4%FE%09%C6%F9%D0%F7%2Fy%BEu%AA%18ooc%2A%FE%98%16%B2%81%F1%F3%7D%AE%BB%A1%D8L%9A%DB%FFmj%A4A%86s%A6%98%1A%94k%D0%FE%11x-%5D%DE%FEt%0B5%3C%CC4%F9b%06x%CE%CA%40%83%AEs%BC%99%E6%B5T%13%A2%08%A6%AC%9C%98%23%E3%5B%C1F%E1%A5%B7%13%B5%C5%EF%80%9E%1F%F1%F3X%E0%04%7D%9Bn%A9%5C%E3%BA%F8hS%A0%D7%A0JF%1F%15%8C%26Vr%FC%03%DD%C8wFm%0630%9F%00%7D%8A%C8%28%84%0B%D6v%08%2F%AA%F0%91f%17X%CD%5B%3A%91%3E%2B%A4%95%B9~%1E_%11%99%A9y%05%80%9F%EB%E3G%3B%1E%253%1F%B53%E8%D0M%267%8E%FD%EEn%91kD%13o%F5%ED%99%E0Dj%BA%033%3F%D7%81%E0%FBY%EC%CF%DF%25F%15et%19%C3m%7Bg%BFLH4%98%B9%D4%1BxgNT%C7G%1C%EDjr2%7F%F7b%3Bfx%12S%DB%92%85%DC%804%85%16%C0~%81%3E%60%95%86%E31%9C%92%F4%EF%D0%5C%80%D6%95%E4%7B%B0%B4%9B%F3a%B5%90%A9%F6%F8%1A%C3%0C%EC%05o%B0%0B%E3%CC%C8x0-%81%EBTq%00j%98%86%0Bo%60%AAz%E6%5D0%8A%CF%83%0E%AA%9EM%7C%C45p%3D%E3%EA%0B%D4%D0F%1B%3EgNej%CC%B8%F9t%15%18%C1%7F%14%D8m%EE%1B%8BwY%0A%EEc%14%94H%CB~%29%C8%B0%FD%FF%F9%86%C3%8Dz%A7%60E%00%00%00%00IEND%AEB%60%82'

// for other layout options see http://js.cytoscape.org/#layouts
const layoutOptions = {
  name: 'cose',
  nodeDimensionsIncludeLabels: true,
  idealEdgeLength: 90,
  nodeRepulsion: 100000,
  gravity: 0.01,
  animate: false,
}

const renderPipelines = function (data) {
  const pipelines = data.pipelines.map((pipeline) => pipeline.name).sort()
  calculatePipelineColours(pipelines)
  renderPipelinesKey(pipelines)

  const container = document.getElementById('graph')

  cy = cytoscape({
    container, // container to render in

    elements: data.elements,

    style: [
      // the stylesheet for the graph
      {
        selector: 'node',
        style: {
          'background-color': '#666',
          label: 'data(id)',
          color: 'white',
        },
      },
      {
        selector: '[type = "plate"]',
        style: {
          shape: 'polygon',
          'shape-polygon-points': platePolygon,
          width: 127.76 / 2,
          height: 85.47 / 2,
        },
      },
      {
        selector: '[size = 384]',
        style: {
          'background-image': bg384,
        },
      },
      {
        selector: '[type = "tube"]',
        style: {
          shape: 'polygon',
          'shape-polygon-points': tubePolygon,
          width: 27 / 2,
          height: 80 / 2,
        },
      },
      {
        selector: '[?input]',
        style: {
          'background-color': '#bbb',
        },
      },
      {
        selector: 'edge',
        style: {
          width: 3,
          'curve-style': 'bezier',
          'line-color': pipelineColourEdge,
          'target-arrow-color': pipelineColourEdge,
          'target-arrow-shape': 'triangle',
          'arrow-scale': 3,
        },
      },
    ],

    layout: layoutOptions,

    minZoom: 0.2,
    maxZoom: 3,
  })
}

// Fetch the result of pipelines.json and then render the graph.
fetch('pipelines.json').then((response) => {
  response.json().then((data) => {
    // Get filter from url
    const url = new URL(window.location.href)
    const filter = url.searchParams.get('filter')
    filterField.value = filter

    // Render the graph
    renderPipelines(data)

    // Apply filter if present
    if (filter) {
      applyFilter(filter)
    }
  })
})

let notResults = undefined
const applyFilter = function (query) {
  if (notResults !== undefined) {
    notResults.restore()
  }

  const all = cy.$('*')
  let results = cy.collection()

  let purposes = cy.$(`node[id @*= "${query}"]`)
  purposes = purposes.union(purposes.neighborhood())
  results = results.union(purposes)

  let pipelines = cy.$(`edge[pipeline @^= "${query}"]`)
  pipelines = pipelines.union(pipelines.connectedNodes())
  results = results.union(pipelines)

  notResults = cy.remove(all.not(results))

  const pipelineNames = [...new Set(results.edges().map((edge) => edge.data('pipeline')))]
  calculatePipelineColours(pipelineNames)
  renderPipelinesKey(pipelineNames)

  results.layout(layoutOptions).run()
}

filterField.addEventListener('change', (event) => {
  const query = event.target.value

  // set url to reflect filter
  const url = new URL(window.location.href)
  url.searchParams.set('filter', query)
  window.history.pushState({}, '', url)

  applyFilter(query)
})
