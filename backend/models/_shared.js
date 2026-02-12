const GeoPointSchema = {
    type: { type: String, enum: ["Point"] }, // Removed default to prevent incomplete objects
    coordinates: {
        type: [Number], // [lng, lat]
        validate: {
            validator: (v) => Array.isArray(v) && v.length === 2,
            message: "coordinates must be [lng, lat]"
        }
    }
};

module.exports = { GeoPointSchema };
