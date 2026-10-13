const fs = require('fs');

const file = 'E:/Websites/Wehere/landing-page/index.html';
let content = fs.readFileSync(file, 'utf8');

const replacements = {
    'self_improvement': 'sparkles',
    'verified_user': 'shield-check',
    'close': 'x',
    'check_circle': 'check-circle',
    'person_off': 'user-minus',
    'sprint': 'zap',
    'domino_mask': 'venetian-mask',
    'sentiment_sad': 'frown',
    'shield_person': 'shield',
    'edit_note': 'pen-line',
    'Share Your Vibe': 'Share Your Feeling'
};

for (const [key, value] of Object.entries(replacements)) {
    content = content.replace(new RegExp(key, 'g'), value);
}

fs.writeFileSync(file, content);
console.log('Icons and text replaced in index.html');
