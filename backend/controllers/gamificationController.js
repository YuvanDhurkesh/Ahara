const User = require('../models/User');

// Points Configuration
const POINTS_CONFIG = {
    POST_DONATION: 50,
    COMPLETE_DONATION: 100,
    COMPLETE_DELIVERY: 200,
    RECEIVE_REVIEW: 10
};

// Badges Configuration
const BADGES = {
    NEWCOMER: "Newcomer",
    GIVER: "Generous Giver",
    HERO: "Zero Waste Hero",
    SUPER_VOLUNTEER: "Super Volunteer"
};

exports.addPoints = async (req, res) => {
    try {
        const { userId, actionType } = req.body;

        const user = await User.findOne({ firebaseUid: userId });
        if (!user) return res.status(404).json({ error: "User not found" });

        let pointsToAdd = 0;
        switch (actionType) {
            case 'POST_DONATION': pointsToAdd = POINTS_CONFIG.POST_DONATION; break;
            case 'COMPLETE_DONATION': pointsToAdd = POINTS_CONFIG.COMPLETE_DONATION; break;
            case 'COMPLETE_DELIVERY': pointsToAdd = POINTS_CONFIG.COMPLETE_DELIVERY; break;
            case 'RECEIVE_REVIEW': pointsToAdd = POINTS_CONFIG.RECEIVE_REVIEW; break;
            default: return res.status(400).json({ error: "Invalid action type" });
        }

        user.points += pointsToAdd;

        // Level Calculation (Simple: Level up every 500 points)
        const newLevel = Math.floor(user.points / 500) + 1;
        if (newLevel > user.level) {
            user.level = newLevel;
            // potential notification logic here
        }

        // Badge Awarding Logic
        if (user.points >= 100 && !user.badges.includes(BADGES.NEWCOMER)) {
            user.badges.push(BADGES.NEWCOMER);
        }
        if (user.points >= 1000 && !user.badges.includes(BADGES.GIVER)) {
            user.badges.push(BADGES.GIVER);
        }

        await user.save();

        res.status(200).json({
            message: "Points updated",
            points: user.points,
            level: user.level,
            badges: user.badges,
            added: pointsToAdd
        });

    } catch (error) {
        console.error("Gamification Error:", error);
        res.status(500).json({ error: "Server error updating points" });
    }
};

exports.getGamificationProfile = async (req, res) => {
    try {
        const { userId } = req.params;
        const user = await User.findOne({ firebaseUid: userId });
        if (!user) return res.status(404).json({ error: "User not found" });

        res.status(200).json({
            points: user.points,
            level: user.level,
            badges: user.badges,
            trustScore: user.trustScore
        });
    } catch (error) {
        res.status(500).json({ error: "Server error fetching profile" });
    }
};

exports.updateTrustScore = async (req, res) => {
    try {
        const { userId, verificationStats, performanceStats, feedbackStats } = req.body;

        const user = await User.findOne({ firebaseUid: userId });
        if (!user) return res.status(404).json({ error: "User not found" });

        // Trust Score Algorithm
        // 1. Verification (Max 40)
        let verificationScore = 0;
        if (user.phone) verificationScore += 10;
        // Assuming we add these fields later or pass them in
        if (verificationStats?.isIdVerified) verificationScore += 20;
        if (user.location) verificationScore += 10;

        // 2. Performance (Max 40)
        let performanceScore = 0;
        // Simple logic for now: 2 points per 100 points earned (proxy for activity)
        performanceScore += Math.min(30, Math.floor(user.points / 100) * 2);
        if (performanceStats?.reliabilityRate > 0.95) performanceScore += 10;

        // 3. Feedback (Max 20)
        let feedbackScore = 0;
        if (feedbackStats?.averageRating) {
            feedbackScore = (feedbackStats.averageRating / 5) * 20;
        }

        const totalScore = Math.min(100, verificationScore + performanceScore + feedbackScore);

        user.trustScore = Math.round(totalScore);
        await user.save();

        res.status(200).json({
            message: "Trust score updated",
            trustScore: user.trustScore,
            breakdown: { verificationScore, performanceScore, feedbackScore }
        });

    } catch (error) {
        console.error("Trust Score Error:", error);
        res.status(500).json({ error: "Server error updating trust score" });
    }
};
