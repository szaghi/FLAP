import { withMermaid } from 'vitepress-plugin-mermaid'
import apiSidebar from '../api/_sidebar.json'

// one sidebar for every page but the API, in reading order: the "previous" and "next" links at the bottom of a page
// follow it, so the documentation reads from the first page to the last
const docs = [
  {
    text: 'Start here',
    items: [
      { text: 'Introduction', link: '/guide/' },
      { text: 'Installation', link: '/guide/install' },
    ],
  },
  {
    text: 'Tutorial',
    items: [
      { text: 'Overview',                    link: '/manual/' },
      { text: '1. A first command line',     link: '/manual/tutorial/01-first-cli' },
      { text: '2. Options of every kind',    link: '/manual/tutorial/02-options' },
      { text: '3. Lists and parameters',     link: '/manual/tutorial/03-lists' },
      { text: '4. Commands',                 link: '/manual/tutorial/04-commands' },
      { text: '5. Values from everywhere',   link: '/manual/tutorial/05-sources' },
      { text: '6. Validation',               link: '/manual/tutorial/06-validation' },
      { text: '7. Shipping it',              link: '/manual/tutorial/07-shipping' },
      { text: '8. Testing the command line', link: '/manual/tutorial/08-testing' },
      { text: '9. Asking the user',          link: '/manual/tutorial/09-asking' },
    ],
  },
  {
    text: 'Recipes',
    items: [
      { text: 'Cookbook', link: '/manual/cookbook' },
    ],
  },
  {
    text: 'Reference',
    items: [
      { text: 'Feature map',              link: '/guide/features' },
      { text: 'Defining Arguments',       link: '/guide/arguments' },
      { text: 'Parsing & Getting Values', link: '/guide/parsing' },
      { text: 'Subcommands',              link: '/guide/subcommands' },
      { text: 'Advanced Features',        link: '/guide/advanced' },
      { text: 'Output Formats',           link: '/guide/output' },
      { text: 'Interactive Menus',        link: '/guide/menu' },
      { text: 'Error Codes',              link: '/guide/errors' },
    ],
  },
  {
    text: 'Project',
    items: [
      { text: 'Upgrading',    link: '/guide/migration' },
      { text: 'Changelog',    link: '/guide/changelog' },
      { text: 'Contributing', link: '/guide/contributing' },
    ],
  },
]

export default withMermaid({
  title: 'FLAP Documentation',
  base: '/FLAP/',
  markdown: {
    math: true,
    languages: ['fortran-free-form', 'fortran-fixed-form'],
    languageAlias: {
      'fortran': 'fortran-free-form',
      'f90': 'fortran-free-form',
      'f95': 'fortran-free-form',
      'f03': 'fortran-free-form',
      'f08': 'fortran-free-form',
      'f77': 'fortran-fixed-form',
    },
  },
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Start here', link: '/guide/', activeMatch: '^/guide/(index|install)' },
      { text: 'Tutorial', link: '/manual/tutorial/01-first-cli', activeMatch: '^/manual/(index|tutorial/)' },
      { text: 'Cookbook', link: '/manual/cookbook', activeMatch: '^/manual/cookbook' },
      {
        text: 'Reference',
        link: '/guide/features',
        activeMatch: '^/guide/(features|arguments|parsing|subcommands|advanced|output|menu|errors)',
      },
      { text: 'API', link: '/api/' },
      {
        text: 'Project',
        items: [
          { text: 'Upgrading',    link: '/guide/migration' },
          { text: 'Changelog',    link: '/guide/changelog' },
          { text: 'Contributing', link: '/guide/contributing' },
        ],
      },
    ],
    sidebar: {
      '/guide/': docs,
      '/manual/': docs,
      '/api/': [
        {
          text: 'API Reference',
          items: [
            { text: 'Overview', link: '/api/' },
          ],
        },
        ...apiSidebar,
      ],
    },
    search: {
      provider: 'local',
    },
  },
  mermaid: {},
  vite: {
    // Build with an explicit modern JS target so the docs compile regardless of
    // which mermaid/vitepress/esbuild versions npm resolves. Vite's default
    // es2020 target forces esbuild to down-level modern syntax (e.g. the
    // destructuring mermaid 11.16+ emits), which it refuses to do and the build
    // dies. es2022 needs no lowering and is within VitePress's browser floor.
    build: {
      target: 'es2022',
    },
  },
})
