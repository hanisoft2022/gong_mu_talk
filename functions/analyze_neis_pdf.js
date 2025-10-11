const fs = require('fs');
const pdfParse = require('pdf-parse');

async function analyzePdf(filePath) {
  console.log('=== Analyzing NEIS PDF ===\n');
  
  const dataBuffer = fs.readFileSync(filePath);
  
  try {
    const data = await pdfParse(dataBuffer);
    
    console.log('📄 PDF Basic Info:');
    console.log('  - Pages:', data.numpages);
    console.log('  - Text length:', data.text.length, 'characters');
    
    console.log('\n📋 PDF Metadata:');
    if (data.info) {
      Object.keys(data.info).forEach(key => {
        console.log(`  - ${key}:`, data.info[key]);
      });
    } else {
      console.log('  No metadata found');
    }
    
    console.log('\n🔍 PDF Metadata (detailed):');
    if (data.metadata) {
      console.log(JSON.stringify(data.metadata, null, 2));
    } else {
      console.log('  No detailed metadata found');
    }
    
    console.log('\n📝 Watermark extraction:');
    const lines = data.text.split('\n');
    const watermarkPattern = /(.+?)\/(\d{4}\.\d{2}\.\d{2})\s+(\d{2}:\d{2})\/(.+?)\/(.+)/;
    
    for (let i = 0; i < Math.min(10, lines.length); i++) {
      const match = lines[i].match(watermarkPattern);
      if (match) {
        console.log('  ✅ Watermark found:', lines[i]);
        console.log('    - School:', match[1]);
        console.log('    - Date:', match[2]);
        console.log('    - Time:', match[3]);
        console.log('    - IP:', match[4]);
        console.log('    - Name:', match[5]);
        break;
      }
    }
    
  } catch (error) {
    console.error('Error parsing PDF:', error.message);
  }
}

const pdfPath = '/Users/shaunkim/Downloads/download-5470219112254737.pdf';
analyzePdf(pdfPath);
