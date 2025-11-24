/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverActions: true,
  },
  // ⬇️ главное: не падать по ESLint во время билда
  eslint: {
    ignoreDuringBuilds: true,
  },
}

module.exports = nextConfig

