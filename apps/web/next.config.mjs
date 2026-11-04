import path from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = path.dirname(fileURLToPath(import.meta.url));

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Static export ke folder `out/` (Deploy: Cloudflare Pages / Firebase Hosting).
  output: 'export',
  images: { unoptimized: true },
  // Hosting statis butuh folder + index.html agar `/merchant/` tidak 404.
  trailingSlash: true,
  reactStrictMode: true,
  // Monorepo: kunci root tracing ke folder `apps/web` agar lockfile root tidak dilaporkan.
  outputFileTracingRoot: projectRoot,
};

export default nextConfig;
