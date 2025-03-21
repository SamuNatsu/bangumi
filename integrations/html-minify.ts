import type { AstroIntegration } from "astro";
import { minify, type Options } from "html-minifier-terser";
import chalk from "chalk";
import fs from "node:fs/promises";

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
  useShortDoctype: true
};

// Plugin builder
const htmlMinify = (): AstroIntegration => ({
  name: "html-minify",
  hooks: {
    "astro:build:done": async ({ assets, logger }): Promise<void> => {
      logger.info("Minifying output HTML files...");

      for (const i of assets.values()) {
        for (const j of i) {
          if (j.pathname.endsWith(".html")) {
            let oldSize: number = 0;
            let newSize: number = 0;

            await fs
              .readFile(j.pathname, "utf-8")
              .then((s: string): Promise<string> => {
                oldSize = s.length;
                return minify(s, options);
              })
              .then((s: string): Promise<void> => {
                newSize = s.length;
                return fs.writeFile(j.pathname, s, "utf-8");
              });

            logger.info(
              chalk.gray(
                "  " +
                  j.pathname +
                  " " +
                  `(-${(((oldSize - newSize) / oldSize) * 100).toFixed(1)}%)`
              )
            );
          }
        }
      }

      logger.info("Done");
    }
  }
});

// Export builder
export default htmlMinify;
