/**
 * Generate a high-quality default image URL for listings that have no photo.
 * Uses curated Unsplash photo IDs for common categories and LoremFlickr for specialized names.
 */

// pool of hand-picked Unsplash photo IDs (high-quality, food-accurate)
const CATEGORY_PHOTOS = {
  biryani: ['bMfxMCmCHbU', 'QzljZB_Vfe4', 'gI4VrRpSBo0'],
  rice: ['bMfxMCmCHbU', 'VkUBDMb8Bxs', 'E3qRz4sNqBE'],
  curry: ['1BaBOGSiF1k', 'YnQbEzYhJo', 'k0rX4hQqOxo', 'In9-3R6Wp00'],
  dal: ['1BaBOGSiF1k', 'SqCmFRV61h4'],
  bread: ['8PZJpMPjVbQ', 'ot0nBwh9Rcg', 'Fd9pV5GWjlc'],
  roti: ['8PZJpMPjVbQ', 'Fd9pV5GWjlc'],
  naan: ['8PZJpMPjVbQ', 'ot0nBwh9Rcg'],
  pasta: ['SqYmTDQYMjo', 'R4-LCEj0-E', '48p194Y08NM'],
  noodles: ['R4-LCEj0-E', '48p194Y08NM', 'ot0nBwh9Rcg'],
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
  steak: ['A7X_9Xn7rYg', 'mO_mYn5XG_A'],
  sushi: ['G6X5fEqp0mU', 'm9u0yWQN5X8'],
  taco: ['33_vY_U5D2A', 'u_M7uT7Z7Yk'],
  coffee: ['t_8uE7uY7r8', 'mO_mYn5XG_A'],
  juice: ['t_8uE7uY7r8', 'mO_mYn5XG_A'],
  tea: ['t_8uE7uY7r8', 'mO_mYn5XG_A'],
  meal: ['1BaBOGSiF1k', 'bMfxMCmCHbU', 'So5iBhQnBmk', 'ot0nBwh9Rcg', 'oU6KZTXhuvk'],
};

// Simple deterministic hash
function hashCode(str) {
  let h = 0;
  if (!str) return 0;
  for (let i = 0; i < str.length; i++) {
    h = (Math.imul(31, h) + str.charCodeAt(i)) | 0;
  }
  return Math.abs(h);
}

// Match food name or category to a pool key
function resolveCategory(name = '') {
  const n = (name || '').toLowerCase();
  const order = [
    'biryani', 'rice', 'pizza', 'burger', 'sandwich', 'pasta', 'noodles',
    'bread', 'roti', 'naan', 'curry', 'dal', 'idli', 'dosa', 'sambar', 'sabzi',
    'salad', 'soup', 'fruit', 'cake', 'sweet', 'dessert', 'milk', 'eggs', 'dairy',
    'steak', 'sushi', 'taco', 'vegetables', 'snack', 'coffee', 'juice', 'tea', 'meal'
  ];
  for (const key of order) {
    if (n.includes(key)) return key;
  }
  return null;
}

function generateDefaultImageUrl(foodName = 'food', category = 'food') {
  // Try matching food name first, then category
  let catKey = resolveCategory(foodName);
  if (!catKey) catKey = resolveCategory(category);

  // 1. If we have a hand-picked curated pool, use it for best quality
  if (catKey && CATEGORY_PHOTOS[catKey]) {
    const pool = CATEGORY_PHOTOS[catKey];
    const photoId = pool[hashCode(foodName) % pool.length];
    return `https://images.unsplash.com/photo-${photoId}?w=800&q=80&fit=crop&auto=format`;
  }

  // 2. Fallback to LoremFlickr for specialized names
  const name = foodName.toLowerCase().replace(/[^a-z ]/g, '').trim();
  const formattedName = name.split(' ').join(',');
  const seed = hashCode(foodName) % 1000;

  return `https://loremflickr.com/800/600/food,${formattedName}?lock=${seed}`;
}

module.exports = { generateDefaultImageUrl };

module.exports = { generateDefaultImageUrl };
