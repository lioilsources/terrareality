# Build context: repository root (needs packages/ui and packages/contracts).
# The build output is plain JavaScript: build on the builder's platform (fast amd64 images on arm64).
FROM --platform=$BUILDPLATFORM node:25-alpine AS build
WORKDIR /repo
COPY package.json package-lock.json .npmrc ./
COPY apps/web/package.json apps/web/
COPY apps/site/package.json apps/site/
COPY packages/contracts/package.json packages/contracts/
COPY packages/ui/package.json packages/ui/
RUN npm ci --ignore-scripts
COPY packages packages
COPY apps/web apps/web
RUN cd apps/web && npm run i18n && npx svelte-kit sync && npm run build

FROM node:25-alpine
WORKDIR /app
ENV NODE_ENV=production PORT=3000
COPY --from=build /repo/apps/web/build ./build
COPY --from=build /repo/apps/web/package.json ./
USER node
EXPOSE 3000
CMD ["node", "build"]
