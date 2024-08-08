# use the official Bun image
# see all versions at https://hub.docker.com/r/oven/bun/tags
FROM oven/bun:1.1.22-alpine AS base
WORKDIR /usr/src/app

# install dependencies into temp directory
# this will cache them and speed up future builds
FROM base AS dev-deps
RUN mkdir -p /tmp/bun
COPY package.json bun.lockb /tmp/bun/
RUN cd /tmp/bun && bun install --frozen-lockfile

# install with --production (exclude devDependencies)
FROM base AS deps
RUN mkdir -p /tmp/bun
COPY package.json bun.lockb /tmp/bun/
RUN cd /tmp/bun && bun install --frozen-lockfile --production

# copy node_modules from temp directory
# then copy all (non-ignored) project files into the image
FROM base AS prerelease
COPY --from=dev-deps /tmp/bun/node_modules node_modules
COPY . .

# [optional] tests & build
# ENV NODE_ENV=production
# RUN bun test

# copy production dependencies and source code into final image
FROM base AS release
COPY --from=deps --chown=bun:bun /tmp/bun/node_modules node_modules
COPY --from=prerelease --chown=bun:bun /usr/src/app/browser.ts .
COPY --from=prerelease --chown=bun:bun /usr/src/app/server.ts .
COPY --from=prerelease --chown=bun:bun /usr/src/app/package.json .

# run the app
USER bun
EXPOSE 3000/tcp
ENTRYPOINT [ "bun", "start" ]