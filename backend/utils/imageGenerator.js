/**
 * Generate a default image URL for listings when no image is uploaded
 */

// Category to real food image keywords
// Using LoremFlickr for high-quality real food images
/**
 * Generate a default image URL for listings when no image is uploaded
 */

function generateDefaultImageUrl(foodName = 'food', category = 'food') {
  const name = (foodName || 'food').toLowerCase();
  
  // Use 'food' as the primary mandatory tag. 
  // We use AND logic (no /all) to ensure we always get food.
  const tags = ['food'];
  
  // Add ONE specific, high-reliability tag based on the food name
  if (name.includes('chaap') || name.includes('soya')) tags.push('curry');
  else if (name.includes('biryani') || name.includes('rice')) tags.push('rice');
  else if (name.includes('bread') || name.includes('roti') || name.includes('naan')) tags.push('bread');
  else if (name.includes('pasta') || name.includes('noodle')) tags.push('pasta');
  else if (name.includes('pizza')) tags.push('pizza');
  else if (name.includes('burger')) tags.push('burger');
  else if (name.includes('fruit')) tags.push('fruit');
  else if (name.includes('cake') || name.includes('pastry') || name.includes('sweet')) tags.push('dessert');
  else if (name.includes('grocery') || name.includes('veg')) tags.push('vegetables');
  else tags.push('meal');

  const seed = Math.abs(foodName.split('').reduce((a, b) => { a = ((a << 5) - a) + b.charCodeAt(0); return a & a; }, 0) % 1000);
  
  // Result: https://loremflickr.com/800/600/food,tag?lock=seed
  // This forces the image to match BOTH 'food' and the tag, preventing random cat statues.
  return `https://loremflickr.com/800/600/${tags.join(',')}?lock=${seed}`;
}

module.exports = {
  generateDefaultImageUrl
};

module.exports = {
  generateDefaultImageUrl
};
