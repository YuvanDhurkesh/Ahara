/**
 * Generate a high-quality default image URL for listings that have no photo.
 * Uses curated Unsplash photo IDs per food category — permanent, no API key needed.
 */

// Each key maps to a pool of hand-picked Unsplash photo IDs (all food-accurate).
const CATEGORY_PHOTOS = {
  biryani: ['bMfxMCmCHbU', 'QzljZB_Vfe4', 'gI4VrRpSBo0'],
  rice: ['bMfxMCmCHbU', 'VkUBDMb8Bxs', 'E3qRz4sNqBE'],
  curry: ['1BaBOGSiF1k', 'YnQbEzYhJo', 'k0rX4hQqOxo'],
  dal: ['1BaBOGSiF1k', 'SqCmFRV61h4'],
  bread: ['8PZJpMPjVbQ', 'ot0nBwh9Rcg', 'Fd9pV5GWjlc'],
  roti: ['8PZJpMPjVbQ', 'Fd9pV5GWjlc'],
  naan: ['8PZJpMPjVbQ', 'ot0nBwh9Rcg'],
  pasta: ['pMW4jzELQCw', 'SqYmTDQYMjo', 'R4-LCEj0-E'],
  noodles: ['pMW4jzELQCw', 'R4-LCEj0-E'],
  pizza: ['oU6KZTXhuvk', 'bELvIg_KZGU', 'yszTabh9ux0'],
  burger: ['So5iBhQnBmk', 'MMGP4kHH-5g', 'uQs1802D0CQ'],
  sandwich: ['So5iBhQnBmk', 'uQs1802D0CQ'],
  salad: ['IGfIGP5ONV0', '9H9oEGNa9ps', 'YJdCZba0TYE'],
  fruit: ['IGfIGP5ONV0', 'YnQbEzYhJo', 'a2XpxdFb2l8'],
  dessert: ['SxIYUGd6cFo', '85zVPGWtWxI', '3iqxDmGOi4g'],
  cake: ['SxIYUGd6cFo', '85zVPGWtWxI'],
  sweet: ['SxIYUGd6cFo', '3iqxDmGOi4g'],
  soup: ['YhgFUd0AvjI', 'k0rX4hQqOxo'],
  idli: ['1BaBOGSiF1k', 'SqCmFRV61h4'],
  dosa: ['1BaBOGSiF1k', 'SqCmFRV61h4'],
  sambar: ['1BaBOGSiF1k', 'k0rX4hQqOxo'],
  sabzi: ['1BaBOGSiF1k', 'SqCmFRV61h4'],
  vegetables: ['0sNnbH8TLBU', 'YnQbEzYhJo', '9H9oEGNa9ps'],
  dairy: ['ouE9JUkB_Ow', '8PZJpMPjVbQ'],
  milk: ['ouE9JUkB_Ow'],
  eggs: ['ouE9JUkB_Ow', 'SqCmFRV61h4'],
  snack: ['MMGP4kHH-5g', 'uQs1802D0CQ'],
  // Generic fallback pool — always accurate food images
  meal: ['1BaBOGSiF1k', 'bMfxMCmCHbU', 'So5iBhQnBmk', 'pMW4jzELQCw', 'oU6KZTXhuvk'],
};

// Simple deterministic hash → consistent image for the same food name
function hashCode(str) {
  let h = 0;
  for (let i = 0; i < str.length; i++) {
    h = (Math.imul(31, h) + str.charCodeAt(i)) | 0;
  }
  return Math.abs(h);
}

// Match food name to a category key
function resolveCategory(foodName = '') {
  const name = foodName.toLowerCase();
  const order = [
    'biryani', 'rice', 'pizza', 'burger', 'sandwich', 'pasta', 'noodles',
    'bread', 'roti', 'naan', 'curry', 'dal', 'idli', 'dosa', 'sambar', 'sabzi',
    'salad', 'soup', 'fruit', 'cake', 'sweet', 'dessert', 'milk', 'eggs', 'dairy',
    'vegetables', 'snack',
  ];
  for (const key of order) {
    if (name.includes(key)) return key;
  }
  return 'meal'; // fallback
}

function generateDefaultImageUrl(foodName = 'food', category = 'food') {
  const catKey = resolveCategory(foodName);
  const pool = CATEGORY_PHOTOS[catKey] || CATEGORY_PHOTOS.meal;
  const photoId = pool[hashCode(foodName) % pool.length];
  // Unsplash direct photo URL — permanent, no API key required
  return `https://images.unsplash.com/photo-${photoId}?w=800&q=80&fit=crop&auto=format`;
}

module.exports = { generateDefaultImageUrl };
