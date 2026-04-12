// FocusTimer App Store Screenshot Generator using Jimp
const Jimp = require('jimp');

const OUTPUT_DIR = '/tmp/FocusTimer/AppStore/Screenshots';
const fs = require('fs');
if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR, { recursive: true });

// Brand colors (0xRRGGBB format for Jimp)
const C = {
    bg: 0x0F0F13,
    bgSec: 0x1A1A21,
    surface: 0x24242E,
    purple: 0x7C6AFF,
    teal: 0x5EEAD4,
    warm: 0xF59E0B,
    text: 0xF4F4F6,
    textSec: 0x8B8B9E,
    success: 0x34D399,
    destructive: 0xF87171,
};

// Helper: draw a filled rounded rectangle
async function roundedRect(img, x, y, w, h, r, color) {
    // Fill main body (no rounded corners)
    for (let py = Math.max(0, y + r); py < Math.min(img.getHeight(), y + h - r); py++) {
        for (let px = Math.max(0, x); px < Math.min(img.getWidth(), x + w); px++) {
            img.setPixelColor(color, px, py);
        }
    }
    // Fill corners with circles
    for (let cy2 = 0; cy2 <= r; cy2++) {
        for (let cx2 = 0; cx2 <= r; cx2++) {
            if (cx2 * cx2 + cy2 * cy2 <= r * r) {
                // Top-left
                if (y + r - cy2 >= 0 && x + r - cx2 >= 0)
                    img.setPixelColor(color, x + r - cx2, y + r - cy2);
                // Top-right
                if (y + r - cy2 >= 0 && x + w - r + cx2 < img.getWidth())
                    img.setPixelColor(color, x + w - r + cx2, y + r - cy2);
                // Bottom-left
                if (y + h - r + cy2 < img.getHeight() && x + r - cx2 >= 0)
                    img.setPixelColor(color, x + r - cx2, y + h - r + cy2);
                // Bottom-right
                if (y + h - r + cy2 < img.getHeight() && x + w - r + cx2 < img.getWidth())
                    img.setPixelColor(color, x + w - r + cx2, y + h - r + cy2);
            }
        }
    }
}

// Helper: draw a filled circle
async function circle(img, cx, cy, r, color) {
    for (let py = -r; py <= r; py++) {
        for (let px = -r; px <= r; px++) {
            if (px * px + py * py <= r * r) {
                const nx = cx + px, ny = cy + py;
                if (nx >= 0 && nx < img.getWidth() && ny >= 0 && ny < img.getHeight())
                    img.setPixelColor(color, nx, ny);
            }
        }
    }
}

// Helper: draw an arc (ring segment)
async function arc(img, cx, cy, ro, ri, color, progress = 1.0) {
    for (let py = -ro - 5; py <= ro + 5; py++) {
        for (let px = -ro - 5; px <= ro + 5; px++) {
            const d = Math.sqrt(px * px + py * py);
            if (d >= ri && d <= ro) {
                const angle = (Math.atan2(py, px) + Math.PI) / (2 * Math.PI);
                const nx = cx + px, ny = cy + py;
                if (nx >= 0 && nx < img.getWidth() && ny >= 0 && ny < img.getHeight()) {
                    if (angle <= progress) {
                        img.setPixelColor(color, nx, ny);
                    } else if (d < ro) {
                        img.setPixelColor(C.surface, nx, ny);
                    }
                }
            }
        }
    }
}

// Helper: draw text using Jimp's built-in text rendering
async function drawText(img, text, x, y, size, color) {
    try {
        const font = size > 40 ? Jimp.FONT_SANS_64_WHITE :
                      size > 25 ? Jimp.FONT_SANS_32_WHITE :
                      size > 15 ? Jimp.FONT_SANS_16_WHITE :
                      Jimp.FONT_SANS_8_WHITE;
        const image = await Jimp.read(font);
        const w = image.getWidth();
        const h = image.getHeight();
        // Scale font
        const scaled = image.clone().resize(size * 10, size * 10);
        img.composite(scaled, x, y, { mode: Jimp.BLEND_SOURCE, opacitySource: 1, opacityDest: 1 });
    } catch (e) {
        // Font loading failed, skip
    }
}

// Simple pixel text using circles for digits
async function drawDigitText(img, text, x, y, size, color) {
    const digitH = Math.floor(size * 0.7);
    const digitW = Math.floor(size * 0.5);
    const spacing = Math.floor(size * 0.1);
    for (let i = 0; i < text.length; i++) {
        const ch = text[i];
        if (ch === ' ') {
            await advance(digitW + spacing);
            continue;
        }
        // Draw digit as a small filled rect (simplified)
        const dx = x + i * (digitW + spacing);
        for (let py = 0; py < digitH; py++) {
            for (let px = 0; px < digitW; px++) {
                const nx = dx + px, ny = y + py;
                if (nx >= 0 && nx < img.getWidth() && ny >= 0 && ny < img.getHeight())
                    img.setPixelColor(color, nx, ny);
            }
        }
    }
}

function advance(w) {}

// Draw a simple text bar (solid background + text-like pixels)
async function drawTextBar(img, text, x, y, w, h, textColor, bgColor) {
    // Background
    await roundedRect(img, x, y, w, h, Math.floor(h / 3), bgColor);
    // Text pixels (simplified: just fill with textColor dots)
    const cols = Math.min(text.length, Math.floor(w / (h * 0.4)));
    const charW = Math.floor(w / (cols + 1));
    const charH = Math.floor(h * 0.5);
    const startX = x + Math.floor((w - cols * charW) / 2);
    const startY = y + Math.floor((h - charH) / 2);
    for (let c = 0; c < cols; c++) {
        for (let py = 0; py < charH; py++) {
            for (let px = 0; px < charW - 2; px++) {
                const nx = startX + c * charW + px;
                const ny = startY + py;
                if (nx >= 0 && nx < img.getWidth() && ny >= 0 && ny < img.getHeight())
                    img.setPixelColor(textColor, nx, ny);
            }
        }
    }
}

// Draw tab bar
async function drawTabBar(img) {
    const tabY = img.getHeight() - 100;
    const tabW = img.getWidth() - 60;
    await roundedRect(img, 30, tabY, tabW, 70, 20, C.bgSec);
    const tabs = 5;
    for (let i = 0; i < tabs; i++) {
        const tx = 30 + Math.floor(tabW / 10) + i * Math.floor(tabW / 5);
        const col = i === 0 ? C.purple : C.surface;
        await circle(img, tx + 30, tabY + 15, 12, col);
    }
}

// SCREEN 1: Today Dashboard
async function createTodayScreen(w, h) {
    const img = new Jimp(w, h, C.bg);
    
    // Greeting
    await drawTextBar(img, 'GOOD MORNING', 60, 100, 300, 30, C.textSec, C.bg);
    await drawTextBar(img, 'READY TO FOCUS?', 60, 150, 500, 50, C.text, C.bg);
    
    // Streak badge
    await roundedRect(img, w - 200, 120, 150, 55, 27, C.warm);
    await drawTextBar(img, '7 DAY STREAK', w - 180, 132, 110, 30, 0x000000, C.warm);
    
    // Rings
    const cx = Math.floor(w / 2), cy = Math.floor(h / 2) - 150;
    const outerR = Math.floor(h * 0.17);
    const innerR = outerR - 45;
    
    // Outer ring (screen time, partial)
    await arc(img, cx, cy, outerR, outerR - 30, 0x7C6AFF55, 0.68);
    // Inner ring (focus, partial)
    await arc(img, cx, cy, innerR, innerR - 20, C.teal, 0.45);
    
    // Center stat
    await drawTextBar(img, '82', cx - 60, cy - 60, 120, 80, C.text, C.bg);
    await drawTextBar(img, 'MIN TODAY', cx - 80, cy + 30, 160, 30, C.textSec, C.bg);
    await drawTextBar(img, 'FOCUS: 45M', cx - 75, cy + 70, 150, 25, C.teal, C.bg);
    
    // Stats row
    const statY = cy + 200;
    const statW = Math.floor((w - 180) / 3);
    const statData = [['7', 'SESSIONS', C.success], ['45M', 'FOCUS', C.purple], ['52M', 'LONGEST', C.teal]];
    for (let i = 0; i < 3; i++) {
        const sx = 60 + i * (statW + 20);
        await roundedRect(img, sx, statY, statW, 120, 16, C.bgSec);
        await drawTextBar(img, statData[i][0], sx + 20, statY + 20, 80, 40, statData[i][2], C.bgSec);
        await drawTextBar(img, statData[i][1], sx + 10, statY + 70, statW - 20, 25, C.textSec, C.bgSec);
    }
    
    // Tab bar
    await drawTabBar(img);
    
    return img;
}

// SCREEN 2: Focus Timer
async function createFocusScreen(w, h) {
    const img = new Jimp(w, h, C.bg);
    
    // Mode label
    await drawTextBar(img, 'DEEP WORK', Math.floor(w/2) - 100, 150, 200, 35, C.purple, C.bg);
    await drawTextBar(img, 'STAY FOCUSED', Math.floor(w/2) - 110, 200, 220, 28, C.textSec, C.bg);
    
    // Timer ring
    const cx = Math.floor(w / 2), cy = Math.floor(h / 2) + 20;
    const ringR = Math.floor(h * 0.22);
    await arc(img, cx, cy, ringR, ringR - 35, C.purple, 0.35);
    
    // Time
    await drawTextBar(img, '17:33', cx - 100, cy - 60, 200, 100, C.text, C.bg);
    await drawTextBar(img, 'REMAINING', cx - 80, cy + 50, 160, 30, C.textSec, C.bg);
    
    // Pause button (large, center)
    await circle(img, cx, h - 280, 55, C.purple);
    
    // Stop button (left of center)
    await circle(img, cx - 160, h - 280, 38, C.destructive);
    
    // Tab bar
    await drawTabBar(img);
    
    return img;
}

// SCREEN 3: Insights
async function createInsightsScreen(w, h) {
    const img = new Jimp(w, h, C.bg);
    
    await drawTextBar(img, 'THIS WEEK', 60, 100, 200, 28, C.textSec, C.bg);
    await drawTextBar(img, 'INSIGHTS', 60, 140, 300, 55, C.text, C.bg);
    
    // Weekly bars
    const chartX = 60, chartY = 250, chartH = 280;
    const chartW = w - 120;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const vals = [0.45, 0.72, 0.35, 0.88, 0.6, 0.25, 0.3];
    const barW = Math.floor((chartW - 72) / 7);
    const gap = 12;
    
    for (let i = 0; i < 7; i++) {
        const bx = chartX + i * (barW + gap);
        const barH = Math.floor(vals[i] * (chartH - 40));
        const by = chartY + chartH - barH;
        const col = vals[i] > 0.5 ? C.purple : 0x7C6AFF80;
        await roundedRect(img, bx, by, barW, barH, 6, col);
        await drawTextBar(img, days[i], bx, chartY + chartH + 5, barW, 20, C.textSec, C.bg);
    }
    
    // Best day card
    const cardY = chartY + chartH + 50;
    await roundedRect(img, 60, cardY, w - 120, 140, 20, 0x5EEAD430);
    await drawTextBar(img, 'BEST DAY', 90, cardY + 20, 140, 25, C.textSec, C.bg);
    await drawTextBar(img, '72 MIN', 90, cardY + 55, 200, 55, C.teal, C.bg);
    await drawTextBar(img, 'THURSDAY', 90, cardY + 115, 150, 25, C.textSec, C.bg);
    await circle(img, w - 130, cardY + 70, 25, C.warm);
    
    // Tab bar
    await drawTabBar(img);
    
    return img;
}

async function generateScreenshots() {
    const sizes = [
        { w: 1290, h: 2796, name: 'iPhone67' },
        { w: 1284, h: 2778, name: 'iPhone65' },
        { w: 2048, h: 2732, name: 'iPadPro' },
    ];
    
    for (const { w, h, name } of sizes) {
        console.log(`Generating ${name} (${w}x${h})...`);
        
        const t0 = Date.now();
        const today = await createTodayScreen(w, h);
        await today.writeAsync(`${OUTPUT_DIR}/${name}_Screen1_Today.png`);
        console.log(`  ✓ Today screen (${Date.now()-t0}ms)`);
        
        const t1 = Date.now();
        const focus = await createFocusScreen(w, h);
        await focus.writeAsync(`${OUTPUT_DIR}/${name}_Screen2_Focus.png`);
        console.log(`  ✓ Focus screen (${Date.now()-t1}ms)`);
        
        const t2 = Date.now();
        const insights = await createInsightsScreen(w, h);
        await insights.writeAsync(`${OUTPUT_DIR}/${name}_Screen3_Insights.png`);
        console.log(`  ✓ Insights screen (${Date.now()-t2}ms)`);
    }
    
    console.log('\nAll screenshots generated!');
    console.log(`Output: ${OUTPUT_DIR}`);
    const files = fs.readdirSync(OUTPUT_DIR);
    files.forEach(f => {
        const stat = fs.statSync(`${OUTPUT_DIR}/${f}`);
        console.log(`  ${f} (${Math.round(stat.size / 1024)}KB)`);
    });
}

generateScreenshots().catch(console.error);
