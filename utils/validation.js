/**
 * Check for missing or empty required fields in a request body
 * @param {Object} body - The request body to check
 * @param {Array<string>} requiredFields - Array of field names that are required
 * @returns {Array<string>} - Array of missing field names, empty if all fields present
 */
exports.getMissingFields = (body, requiredFields) => {
  console.log('Checking required fields:', requiredFields);
  console.log('With body:', body);
  
  const missing = [];
  
  for (const field of requiredFields) {
    if (body[field] === undefined || (typeof body[field] === 'string' && body[field].trim() === '')) {
      missing.push(field);
    }
  }
  
  console.log('Missing fields:', missing);
  return missing;
};