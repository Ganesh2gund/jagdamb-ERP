import dns from 'node:dns';
// Ensure Windows resolves MongoDB Atlas SRV records properly
try {
  dns.setServers(['8.8.8.8', '1.1.1.1', '8.8.4.4']);
} catch (e) {
  // Ignore if already set or not supported
}

import mongoose from 'mongoose';

export async function connectDB() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.warn('⚠️ MONGODB_URI not found in environment. Running in offline/fallback mode.');
    return false;
  }

  try {
    await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 15000,
    });
    console.log('✅ Connected to MongoDB Atlas Free Tier (Cluster0)!');
    console.log(`📦 Database: ${mongoose.connection.name}`);
    return true;
  } catch (err) {
    console.error('❌ MongoDB Atlas connection error:', err.message);
    console.warn('⚠️ Fallback to local in-memory store active.');
    return false;
  }
}

export default connectDB;
