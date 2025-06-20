import { defineConfig } from "astro/config";

// Integrations
import htmlMinify from "./integrations/html-minify";
import icon from "astro-icon";

// Vite plugins
import font from "vite-plugin-font";
import tailwindcss from "@tailwindcss/vite";

// https://astro.build/config
export default defineConfig({
  integrations: [icon(), htmlMinify()],
  site: "https://bangumi.rainiar.top",
  vite: {
    plugins: [font.vite(), tailwindcss()],
  },
});
