# Third-party notices

Dayweave's original application code is available under the root [MIT License](LICENSE). Third-party code retains its own copyright and license terms.

## Included source and styles

- **OpenAI Sites Vite plugin** — `build/sites-vite-plugin.ts`; copyright (c) 2026 OpenAI. The complete MIT notice is preserved in [build/sites-vite-plugin.LICENSE](build/sites-vite-plugin.LICENSE).
- **shadcn/ui components and styles** — the shadcn-derived components in `components/ui/` and the vendored Tailwind stylesheet in `vendor/shadcn-tailwind-4.13.0.css`. Copyright (c) 2023 shadcn. The complete MIT notice is preserved in [vendor/shadcn-tailwind-4.13.0.LICENSE.md](vendor/shadcn-tailwind-4.13.0.LICENSE.md).

## Package dependencies

Dependencies are declared in `package.json` and pinned in `package-lock.json`. They are installed separately and remain subject to the licenses included with each package. This repository's MIT license does not replace those licenses.

## Product reference

[OCA/project](https://github.com/OCA/project/tree/18.0) informed the timeline, task-note, and parent/child completion concepts. Dayweave does not include OCA module source code; its interface and application logic were implemented independently. OCA modules retain their respective licenses in the upstream repository.
