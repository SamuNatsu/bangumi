import type { AstroIntegration } from "astro";
import { minify, type Options } from "html-minifier-terser";
import chalk from "chalk";
import fs from "node:fs/promises";
import PQueue from "p-queue";

// Minify options
const options: Options = {
  collapseBooleanAttributes: true,
  collapseWhitespace: true,
  conservativeCollapse: true,
  keepClosingSlash: true,
  minifyCSS: true,
  minifyJS: true,
  removeComments: true,
  removeScriptTypeAttributes: true,
  removeStyleLinkTypeAttributes: true,
  sortAttributes: true,
  sortClassName: true,
  useShortDoctype: true,
};

// Plugin builder
const htmlMinify = (): AstroIntegration => ({
  name: "html-minify",
  hooks: {
    "astro:build:done": async ({ assets, logger }) => {
      logger.info("Minifying output HTML files...");

      const tasks = assets
        .values()
        .flatMap((urls) =>
          urls
            .filter((url) => url.pathname.endsWith(".html"))
            .map((url) => async () => {
              let oldSize = 0;
              let newSize = 0;

              await fs
                .readFile(url.pathname, "utf-8")
                .then((data) => {
                  oldSize = data.length;
                  return minify(data, options);
                })
                .then((data) => {
                  newSize = data.length;
                  return fs.writeFile(url.pathname, data, "utf-8");
                });

              const rate = ((oldSize - newSize) / oldSize) * 100;
              logger.info(
                chalk.gray("  " + url.pathname + ` (-${rate.toFixed(1)}%)`),
              );
            }),
        )
        .toArray();

      const queue = new PQueue({ concurrency: 8 });
      await queue.addAll(tasks);

      logger.info("Done");
    },
  },
});

// Export builder
export default htmlMinify;
